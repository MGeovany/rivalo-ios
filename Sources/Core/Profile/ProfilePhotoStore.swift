import Foundation
import UIKit

/// Persists the player card photo locally (per user id) until the backend supports avatars.
enum ProfilePhotoStore {
    private static let folderName = "profile-photos"

    static func load(userId: String) -> Data? {
        let url = fileURL(userId: userId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func save(userId: String, pngData: Data) -> Data? {
        let url = fileURL(userId: userId)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try pngData.write(to: url, options: .atomic)
            return pngData
        } catch {
            return nil
        }
    }

    static func delete(userId: String) {
        try? FileManager.default.removeItem(at: fileURL(userId: userId))
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
        guard let image = UIImage(data: data) else { return nil }
        let normalized = normalized(image)
        let resized = resize(normalized, maxPixel: maxPixel)
        let cutout = await BackgroundRemover.removeBackground(from: resized) ?? resized
        return cutout.pngData()
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
