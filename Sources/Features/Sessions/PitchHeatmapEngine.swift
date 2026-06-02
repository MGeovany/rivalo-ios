import CoreImage
import UIKit

/// Renders a smooth pitch heatmap (density splats + blur + green→red ramp).
enum PitchHeatmapEngine {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private static let gradientImage: CIImage? = makeGradientImage()

    static func renderHeatLayer(track: [SessionActivityGeometry.PitchPoint], size: CGSize) -> UIImage? {
        guard !track.isEmpty, size.width > 1, size.height > 1 else { return nil }

        let cols = 96
        let rows = 64
        let grid = SessionActivityGeometry.heatGrid(from: track, cols: cols, rows: rows)
        let maxVal = grid.flatMap { $0 }.max() ?? 1
        guard maxVal > 0 else { return nil }

        var bytes = [UInt8](repeating: 0, count: cols * rows)
        for r in 0..<rows {
            for c in 0..<cols {
                let normalized = pow(grid[r][c] / maxVal, 0.72)
                bytes[r * cols + c] = UInt8(min(255, normalized * 255))
            }
        }

        guard let gray = CIImage(
            bitmapData: Data(bytes),
            bytesPerRow: cols,
            size: CGSize(width: cols, height: rows),
            format: .L8,
            colorSpace: CGColorSpaceCreateDeviceGray()
        ) else { return nil }

        let scaleX = size.width / CGFloat(cols)
        let scaleY = size.height / CGFloat(rows)
        let scaled = gray.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let extent = scaled.extent

        let blurred = scaled
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 26])
            .cropped(to: extent)

        let colorized = colorize(blurred)
        guard let cg = ciContext.createCGImage(colorized, from: extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    private static func colorize(_ image: CIImage) -> CIImage {
        guard let gradientImage else { return image }
        return image
            .applyingFilter(
                "CIColorMap",
                parameters: ["inputGradientImage": gradientImage]
            )
            .applyingFilter(
                "CIColorControls",
                parameters: [
                    kCIInputSaturationKey: 1.35,
                    kCIInputContrastKey: 1.12,
                    kCIInputBrightnessKey: 0.04,
                ]
            )
    }

    private static func makeGradientImage() -> CIImage? {
        let width = 512
        let height = 4
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let t = Double(x) / Double(width - 1)
                let color = heatRampColor(t: t)
                let offset = (y * width + x) * 4
                pixels[offset] = UInt8(color.r * 255)
                pixels[offset + 1] = UInt8(color.g * 255)
                pixels[offset + 2] = UInt8(color.b * 255)
                pixels[offset + 3] = UInt8(color.a * 255)
            }
        }

        return CIImage(
            bitmapData: Data(pixels),
            bytesPerRow: width * 4,
            size: CGSize(width: width, height: height),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
    }

    private static func heatRampColor(t: Double) -> (r: Double, g: Double, b: Double, a: Double) {
        if t < 0.12 { return (0.04, 0.18, 0.08, 0) }
        if t < 0.38 { return lerp(t, from: (0.08, 0.45, 0.22, 0.45), to: (0.25, 0.78, 0.28, 0.82), start: 0.12, end: 0.38) }
        if t < 0.58 { return lerp(t, from: (0.25, 0.78, 0.28, 0.82), to: (0.98, 0.92, 0.18, 0.92), start: 0.38, end: 0.58) }
        if t < 0.78 { return lerp(t, from: (0.98, 0.92, 0.18, 0.92), to: (1, 0.52, 0.06, 0.98), start: 0.58, end: 0.78) }
        return lerp(t, from: (1, 0.52, 0.06, 0.98), to: (0.94, 0.1, 0.06, 1), start: 0.78, end: 1)
    }

    private static func lerp(
        _ t: Double,
        from: (Double, Double, Double, Double),
        to: (Double, Double, Double, Double),
        start: Double,
        end: Double
    ) -> (r: Double, g: Double, b: Double, a: Double) {
        let u = (t - start) / (end - start)
        return (
            from.0 + (to.0 - from.0) * u,
            from.1 + (to.1 - from.1) * u,
            from.2 + (to.2 - from.2) * u,
            from.3 + (to.3 - from.3) * u
        )
    }
}
