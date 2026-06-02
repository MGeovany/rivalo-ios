import Foundation
import UIKit

/// Persists the player card photo locally (per user id) until the backend supports avatars.
enum ProfilePhotoStore {
    private static let folderName = "profile-photos"

    static func load(userId: String) -> Data? {
        let url = fileURL(userId: userId)
        guard FileManager.default.fileExists(atPath: url.path) else {
            ProfilePhotoLog.debug("load: no saved photo for user")
            return nil
        }
        let data = try? Data(contentsOf: url)
        ProfilePhotoLog.debug("load: \(data?.count ?? 0) bytes")
        return data
    }

    static func save(userId: String, pngData: Data) -> Data? {
        let url = fileURL(userId: userId)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try pngData.write(to: url, options: .atomic)
            ProfilePhotoLog.info("save: wrote \(pngData.count) bytes to disk")
            return pngData
        } catch {
            ProfilePhotoLog.error("save failed: \(error.localizedDescription)")
            return nil
        }
    }

    static func delete(userId: String) {
        try? FileManager.default.removeItem(at: fileURL(userId: userId))
        ProfilePhotoLog.info("delete: removed saved photo")
    }

    private static func fileURL(userId: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let safeId = userId.replacingOccurrences(of: "/", with: "_")
        return base
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent("\(safeId).png")
    }
}

enum ProfilePhotoProcessor {
    /// Normalizes, downscales, removes background, and returns PNG bytes for the card cutout.
    static func prepareForCard(_ data: Data, maxPixel: CGFloat = 900) async -> Data? {
        ProfilePhotoLog.info("prepareForCard: input \(data.count) bytes")

        guard let image = UIImage(data: data) else {
            ProfilePhotoLog.error("prepareForCard: UIImage decode failed")
            return nil
        }

        let normalized = normalized(image)
        let resized = resize(normalized, maxPixel: maxPixel)
        ProfilePhotoLog.debug(
            "prepareForCard: normalized size \(Int(normalized.size.width))x\(Int(normalized.size.height)), "
                + "resized \(Int(resized.size.width))x\(Int(resized.size.height))"
        )

        guard let cutout = await BackgroundRemover.removeBackground(from: resized) else {
            ProfilePhotoLog.error("prepareForCard: background removal returned nil")
            return nil
        }

        let hasAlpha = hasTransparentBackground(cutout)
        ProfilePhotoLog.info("prepareForCard: cutout ready, hasTransparency=\(hasAlpha)")

        guard hasAlpha else {
            ProfilePhotoLog.error("prepareForCard: cutout has no transparent pixels — treating as failure")
            return nil
        }

        guard let png = cutout.pngData() else {
            ProfilePhotoLog.error("prepareForCard: pngData() failed")
            return nil
        }

        ProfilePhotoLog.info("prepareForCard: success \(png.count) bytes")
        return png
    }

    /// Returns true when the image likely has a removed background (non-opaque pixels).
    static func hasTransparentBackground(_ data: Data) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        return hasTransparentBackground(image)
    }

    static func hasTransparentBackground(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }

        let alphaInfo = cgImage.alphaInfo
        if alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast {
            return false
        }

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

        guard let sampleCG = sample.cgImage,
              let data = sampleCG.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data)
        else {
            return false
        }

        let bytesPerPixel = sampleCG.bitsPerPixel / 8
        guard bytesPerPixel >= 4 else { return false }

        let pixelCount = sampleCG.width * sampleCG.height
        var transparentCount = 0
        for index in 0..<pixelCount {
            let offset = index * bytesPerPixel
            let alpha = bytes[offset + 3]
            if alpha < 250 {
                transparentCount += 1
            }
        }

        let ratio = Double(transparentCount) / Double(pixelCount)
        ProfilePhotoLog.debug("hasTransparentBackground: \(transparentCount)/\(pixelCount) transparent (\(String(format: "%.1f", ratio * 100))%)")
        return transparentCount > pixelCount / 20
    }

    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func resize(_ image: UIImage, maxPixel: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxPixel else { return image }
        let scale = maxPixel / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
