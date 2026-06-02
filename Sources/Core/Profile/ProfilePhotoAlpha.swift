import UIKit

/// Alpha-channel sampling for profile photo cutouts.
enum ProfilePhotoAlpha {
    struct Stats: Equatable {
        let opaqueRatio: Double
        let transparentRatio: Double
    }

    /// A valid cutout has visible subject pixels and removed background pixels.
    static func isValidCutout(_ image: UIImage) -> Bool {
        guard let stats = stats(for: image) else { return false }
        return stats.opaqueRatio >= 0.05 && stats.transparentRatio >= 0.05
    }

    static func stats(for image: UIImage) -> Stats? {
        let sampleSize = 48
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: sampleSize, height: sampleSize),
            format: format
        )
        let sample = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))
        }

        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * 4)
        guard let context = CGContext(
            data: &pixels,
            width: sampleSize,
            height: sampleSize,
            bitsPerComponent: 8,
            bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = sample.cgImage else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        let pixelCount = sampleSize * sampleSize
        var opaqueCount = 0
        var transparentCount = 0
        for index in 0..<pixelCount {
            let alpha = pixels[index * 4 + 3]
            if alpha < 20 {
                transparentCount += 1
            } else if alpha > 230 {
                opaqueCount += 1
            }
        }

        return Stats(
            opaqueRatio: Double(opaqueCount) / Double(pixelCount),
            transparentRatio: Double(transparentCount) / Double(pixelCount)
        )
    }
}
