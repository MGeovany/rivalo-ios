import CoreImage
import UIKit

/// Renders a smooth pitch heatmap (Gaussian blur + color ramp) — no map tiles.
enum PitchHeatmapEngine {
    private static let ciContext = CIContext()

    static func renderHeatLayer(session: SportSession, size: CGSize) -> UIImage? {
        let track = SessionActivityGeometry.pitchTrack(from: session)
        guard !track.isEmpty, size.width > 1, size.height > 1 else { return nil }

        let cols = 80
        let rows = 52
        let grid = SessionActivityGeometry.heatGrid(from: track, cols: cols, rows: rows)
        let maxVal = grid.flatMap { $0 }.max() ?? 1
        guard maxVal > 0 else { return nil }

        var bytes = [UInt8](repeating: 0, count: cols * rows)
        for r in 0..<rows {
            for c in 0..<cols {
                let normalized = grid[r][c] / maxVal
                bytes[r * cols + c] = UInt8(min(255, normalized * 255))
            }
        }

        let gray = CIImage(
            bitmapData: Data(bytes),
            bytesPerRow: cols,
            size: CGSize(width: cols, height: rows),
            format: .L8,
            colorSpace: CGColorSpaceCreateDeviceGray()
        )

        let scaled = gray.transformed(by: CGAffineTransform(scaleX: size.width / CGFloat(cols), y: size.height / CGFloat(rows)))
        let blurred = scaled.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 14])
        let colorized = colorize(blurred)
        guard let cg = ciContext.createCGImage(colorized, from: CGRect(origin: .zero, size: size)) else { return nil }
        return UIImage(cgImage: cg)
    }

    private static func colorize(_ image: CIImage) -> CIImage {
        let falseColor = image.applyingFilter(
            "CIFalseColor",
            parameters: [
                "inputColor0": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                "inputColor1": CIColor(red: 1, green: 0.35, blue: 0.05, alpha: 0.95),
            ]
        )
        return falseColor.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: 1.35,
                kCIInputContrastKey: 1.15,
            ]
        )
    }
}
