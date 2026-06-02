import CoreImage
import CoreImage.CIFilterBuiltins
import CoreML
import UIKit
import Vision

/// Removes the background from a portrait using on-device Vision (iOS 17+).
enum BackgroundRemover {
    static func removeBackground(from image: UIImage) async -> UIImage? {
        ProfilePhotoLog.info("BackgroundRemover: starting (simulator=\(Self.isSimulator))")
        let result = await Task.detached(priority: .userInitiated) {
            performRemoval(on: image)
        }.value
        if result != nil {
            ProfilePhotoLog.info("BackgroundRemover: finished with image")
        } else {
            ProfilePhotoLog.error("BackgroundRemover: finished with nil")
        }
        return result
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private static func performRemoval(on image: UIImage) -> UIImage? {
        guard let cgImage = uprightCGImage(from: image) else {
            ProfilePhotoLog.error("BackgroundRemover: upright bitmap failed")
            return nil
        }
        ProfilePhotoLog.debug("BackgroundRemover: source \(cgImage.width)x\(cgImage.height)")

        if let cutout = foregroundInstanceMask(cgImage: cgImage) {
            ProfilePhotoLog.info("BackgroundRemover: used foreground instance mask")
            return cutout
        }

        for quality in personSegmentationQualities {
            if let cutout = personSegmentation(cgImage: cgImage, quality: quality) {
                ProfilePhotoLog.info("BackgroundRemover: used person segmentation (\(quality))")
                return cutout
            }
        }

        ProfilePhotoLog.error("BackgroundRemover: all strategies failed")
        return nil
    }

    private static var personSegmentationQualities: [VNGeneratePersonSegmentationRequest.QualityLevel] {
        if isSimulator {
            return [.balanced, .fast, .accurate]
        }
        return [.accurate, .balanced, .fast]
    }

    /// Renders the image upright into a bitmap Vision can consume reliably.
    private static func uprightCGImage(from image: UIImage) -> CGImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let bitmap = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return bitmap.cgImage
    }

    private static func configureRequest(_ request: VNRequest) {
        #if targetEnvironment(simulator)
        ProfilePhotoLog.info("Vision: simulator — forcing CPU compute")
        if #available(iOS 17.0, *) {
            do {
                let stageDevices = try request.supportedComputeStageDevices
                if let mainDevices = stageDevices[.main] {
                    ProfilePhotoLog.debug(
                        "Vision: main stage devices=\(mainDevices.map { String(describing: $0) }.joined(separator: ", "))"
                    )
                    if let cpu = mainDevices.first(where: { String(describing: $0).contains("CPU") }) {
                        request.setComputeDevice(cpu, for: .main)
                        return
                    }
                }
            } catch {
                ProfilePhotoLog.error("Vision: supportedComputeStageDevices: \(error.localizedDescription)")
            }
        }
        request.usesCPUOnly = true
        #endif
    }

    private static func foregroundInstanceMask(cgImage: CGImage) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        configureRequest(request)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                ProfilePhotoLog.error("foregroundInstanceMask: no results")
                return nil
            }
            ProfilePhotoLog.debug("foregroundInstanceMask: instances=\(observation.allInstances.count)")
            guard !observation.allInstances.isEmpty else {
                ProfilePhotoLog.error("foregroundInstanceMask: no salient instances")
                return nil
            }
            let pixelBuffer = try observation.generateScaledMaskForImage(
                forInstances: observation.allInstances,
                from: handler
            )
            return applyMask(pixelBuffer: pixelBuffer, to: cgImage)
        } catch {
            ProfilePhotoLog.error("foregroundInstanceMask: \(error.localizedDescription)")
            return nil
        }
    }

    private static func personSegmentation(
        cgImage: CGImage,
        quality: VNGeneratePersonSegmentationRequest.QualityLevel
    ) -> UIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = quality
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        configureRequest(request)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                ProfilePhotoLog.error("personSegmentation(\(quality)): no results")
                return nil
            }
            return applyMask(pixelBuffer: observation.pixelBuffer, to: cgImage)
        } catch {
            ProfilePhotoLog.error("personSegmentation(\(quality)): \(error.localizedDescription)")
            return nil
        }
    }

    private static func applyMask(pixelBuffer: CVPixelBuffer, to cgImage: CGImage) -> UIImage? {
        let ciImage = CIImage(cgImage: cgImage)
        var mask = CIImage(cvPixelBuffer: pixelBuffer)
        let scaleX = ciImage.extent.width / mask.extent.width
        let scaleY = ciImage.extent.height / mask.extent.height
        mask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        if let cutout = blendMask(mask, over: ciImage, invert: false),
           ProfilePhotoAlpha.isValidCutout(cutout) {
            logCutoutStats(cutout, label: "normal mask")
            return cutout
        }

        if let cutout = blendMask(mask, over: ciImage, invert: true),
           ProfilePhotoAlpha.isValidCutout(cutout) {
            ProfilePhotoLog.info("applyMask: used inverted mask")
            logCutoutStats(cutout, label: "inverted mask")
            return cutout
        }

        ProfilePhotoLog.error("applyMask: cutout empty or fully opaque after normal + inverted mask")
        return nil
    }

    private static func blendMask(_ mask: CIImage, over image: CIImage, invert: Bool) -> UIImage? {
        var workingMask = mask
        if invert {
            workingMask = workingMask.applyingFilter("CIColorInvert")
        }
        let transparent = CIImage(color: .clear).cropped(to: image.extent)
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.backgroundImage = transparent
        filter.maskImage = workingMask
        guard let output = filter.outputImage else { return nil }

        let context = CIContext(options: nil)
        guard let outputCG = context.createCGImage(
            output,
            from: image.extent,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        ) else {
            return nil
        }
        return UIImage(cgImage: outputCG, scale: 1, orientation: .up)
    }

    private static func logCutoutStats(_ image: UIImage, label: String) {
        guard let stats = ProfilePhotoAlpha.stats(for: image) else { return }
        ProfilePhotoLog.debug(
            "applyMask \(label): opaque \(String(format: "%.1f", stats.opaqueRatio * 100))%, "
                + "transparent \(String(format: "%.1f", stats.transparentRatio * 100))%"
        )
    }
}
