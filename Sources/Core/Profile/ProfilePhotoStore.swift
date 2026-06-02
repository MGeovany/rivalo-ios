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

        guard ProfilePhotoAlpha.isValidCutout(cutout) else {
            if let stats = ProfilePhotoAlpha.stats(for: cutout) {
                ProfilePhotoLog.error(
                    "prepareForCard: invalid cutout — opaque \(String(format: "%.1f", stats.opaqueRatio * 100))%, "
                        + "transparent \(String(format: "%.1f", stats.transparentRatio * 100))%"
                )
            } else {
                ProfilePhotoLog.error("prepareForCard: invalid cutout — could not sample alpha")
            }
            return nil
        }

        if let stats = ProfilePhotoAlpha.stats(for: cutout) {
            ProfilePhotoLog.info(
                "prepareForCard: valid cutout — opaque \(String(format: "%.1f", stats.opaqueRatio * 100))%, "
                    + "transparent \(String(format: "%.1f", stats.transparentRatio * 100))%"
            )
        }

        guard let png = cutout.pngData() else {
            ProfilePhotoLog.error("prepareForCard: pngData() failed")
            return nil
        }

        ProfilePhotoLog.info("prepareForCard: success \(png.count) bytes")
        return png
    }

    /// Returns true when the image is a cutout with background removed.
    static func hasTransparentBackground(_ data: Data) -> Bool {
        guard let image = UIImage(data: data) else { return false }
        return ProfilePhotoAlpha.isValidCutout(image)
    }

    static func hasTransparentBackground(_ image: UIImage) -> Bool {
        ProfilePhotoAlpha.isValidCutout(image)
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
