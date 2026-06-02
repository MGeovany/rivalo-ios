import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Removes the background from a portrait using on-device Vision (iOS 17+).
enum BackgroundRemover {
    static func removeBackground(from image: UIImage) async -> UIImage? {
        ProfilePhotoLog.info("BackgroundRemover: starting")
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

    private static func performRemoval(on image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else {
            ProfilePhotoLog.error("BackgroundRemover: missing cgImage")
            return nil
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        ProfilePhotoLog.debug(
            "BackgroundRemover: source \(cgImage.width)x\(cgImage.height) orientation=\(orientation.rawValue)"
        )

        if let cutout = foregroundInstanceMask(cgImage: cgImage, orientation: orientation) {
            ProfilePhotoLog.info("BackgroundRemover: used foreground instance mask")
            return cutout
        }

        if let cutout = personSegmentation(cgImage: cgImage, orientation: orientation) {
            ProfilePhotoLog.info("BackgroundRemover: used person segmentation fallback")
            return cutout
        }

        ProfilePhotoLog.error("BackgroundRemover: all strategies failed")
        return nil
    }

    private static func foregroundInstanceMask(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                ProfilePhotoLog.error("foregroundInstanceMask: no results")
                return nil
            }
            ProfilePhotoLog.debug("foregroundInstanceMask: instances=\(observation.allInstances.count)")
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

    private static func personSegmentation(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> UIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                ProfilePhotoLog.error("personSegmentation: no results")
                return nil
            }
            return applyMask(pixelBuffer: observation.pixelBuffer, to: cgImage)
        } catch {
            ProfilePhotoLog.error("personSegmentation: \(error.localizedDescription)")
            return nil
        }
    }

    private static func applyMask(pixelBuffer: CVPixelBuffer, to cgImage: CGImage) -> UIImage? {
        let ciImage = CIImage(cgImage: cgImage)
        var mask = CIImage(cvPixelBuffer: pixelBuffer)
        let scaleX = ciImage.extent.width / mask.extent.width
        let scaleY = ciImage.extent.height / mask.extent.height
        mask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let transparent = CIImage(color: .clear).cropped(to: ciImage.extent)
        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = transparent
        filter.maskImage = mask
        guard let output = filter.outputImage else {
            ProfilePhotoLog.error("applyMask: blendWithMask produced no output")
            return nil
        }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let outputCG = context.createCGImage(output, from: ciImage.extent) else {
            ProfilePhotoLog.error("applyMask: createCGImage failed")
            return nil
        }
        return UIImage(cgImage: outputCG, scale: 1, orientation: .up)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
