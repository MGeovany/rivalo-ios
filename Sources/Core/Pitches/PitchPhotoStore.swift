import Foundation
import UIKit

/// One stored court photo: a stable id (filename) and its JPEG bytes.
struct PitchPhoto: Equatable, Identifiable, Sendable {
    let id: String
    let data: Data
}

/// JPEG photos attached to a court/pitch (device-local), with per-photo delete.
enum PitchPhotoStore {
    private static let folderName = "pitch-photos"

    static func load(pitchId: String) -> [PitchPhoto] {
        let dir = directory(pitchId: pitchId)
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return PitchPhoto(id: url.lastPathComponent, data: data)
            }
    }

    @discardableResult
    static func append(pitchId: String, rawImageData: Data) -> PitchPhoto? {
        let dir = directory(pitchId: pitchId)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Millisecond-precision name keeps ordering stable across rapid adds.
        let name = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let url = dir.appendingPathComponent(name)
        do {
            try rawImageData.write(to: url, options: .atomic)
            return PitchPhoto(id: name, data: rawImageData)
        } catch {
            return nil
        }
    }

    static func delete(pitchId: String, photoId: String) {
        let url = directory(pitchId: pitchId).appendingPathComponent(photoId)
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll(pitchId: String) {
        try? FileManager.default.removeItem(at: directory(pitchId: pitchId))
    }

    private static func directory(pitchId: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let safeId = pitchId.replacingOccurrences(of: "/", with: "_")
        return base.appendingPathComponent(folderName, isDirectory: true).appendingPathComponent(safeId, isDirectory: true)
    }
}
