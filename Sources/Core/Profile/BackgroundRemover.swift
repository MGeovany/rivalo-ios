import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Removes the background from a portrait using on-device Vision (iOS 17+).
enum BackgroundRemover {
    static func removeBackground(from image: UIImage) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            performRemoval(on: image)
        }.value
    }

    private static func performRemoval(on image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        if let cutout = foregroundInstanceMask(cgImage: cgImage, orientation: orientation) {
            return cutout
        }
        return personSegmentation(cgImage: cgImage, orientation: orientation)
    }

    private static func foregroundInstanceMask(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let pixelBuffer = try observation.generateScaledMaskForImage(
                forInstances: observation.allInstances,
                from: handler
            )
            return applyMask(pixelBuffer: pixelBuffer, to: cgImage)
        } catch {
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
            guard let observation = request.results?.first else { return nil }
            return applyMask(pixelBuffer: observation.pixelBuffer, to: cgImage)
        } catch {
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
        guard let output = filter.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let outputCG = context.createCGImage(output, from: ciImage.extent) else { return nil }
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
