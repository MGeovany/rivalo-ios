import Foundation
import UIKit

/// JPEG photos attached to a session (device-local).
enum SessionPhotoStore {
    private static let folderName = "session-photos"

    static func load(sessionId: String) -> [Data] {
        let dir = directory(sessionId: sessionId)
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? Data(contentsOf: $0) }
    }

    @discardableResult
    static func append(sessionId: String, rawImageData: Data) -> Data? {
        guard let prepared = ProfilePhotoProcessor.prepareForCard(rawImageData, maxPixel: 1200) else { return nil }
        let dir = directory(sessionId: sessionId)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = "\(Int(Date().timeIntervalSince1970)).jpg"
        let url = dir.appendingPathComponent(name)
        do {
            try prepared.write(to: url, options: .atomic)
            return prepared
        } catch {
            return nil
        }
    }

    static func deleteAll(sessionId: String) {
        try? FileManager.default.removeItem(at: directory(sessionId: sessionId))
    }

    private static func directory(sessionId: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let safeId = sessionId.replacingOccurrences(of: "/", with: "_")
        return base.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(safeId, isDirectory: true)
    }
}
