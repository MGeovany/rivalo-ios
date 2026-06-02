import Foundation
import UIKit

/// Downloads layered player card PNGs from Supabase Storage and caches them on disk.
actor PlayerCardAssetStore {
    static let shared = PlayerCardAssetStore()

    static let bucket = "player-card-assets"

    private let session: URLSession
    private var memoryCache: [String: UIImage] = [:]
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func uiImage(for rank: PlayerCardRank, layer: PlayerCardLayer) async -> UIImage? {
        let key = cacheKey(for: rank, layer: layer)
        if let cached = memoryCache[key] { return cached }
        if let disk = loadFromDisk(key: key) {
            memoryCache[key] = disk
            return disk
        }
        if let existing = inFlight[key] {
            return await existing.value
        }

        let task = Task<UIImage?, Never> {
            await fetchRemoteImage(key: key, rank: rank, layer: layer)
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            memoryCache[key] = image
        }
        return image
    }

    func prefetchTier(_ rank: PlayerCardRank) async {
        await withTaskGroup(of: Void.self) { group in
            for layer in PlayerCardLayer.allCases {
                group.addTask {
                    _ = await self.uiImage(for: rank, layer: layer)
                }
            }
        }
    }

    // MARK: - Remote

    private func fetchRemoteImage(
        key: String,
        rank: PlayerCardRank,
        layer: PlayerCardLayer
    ) async -> UIImage? {
        guard let url = Self.publicURL(for: rank, layer: layer) else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            guard let image = UIImage(data: data) else { return nil }
            saveToDisk(data: data, key: key)
            return image
        } catch {
            return nil
        }
    }

    static func publicURL(for rank: PlayerCardRank, layer: PlayerCardLayer) -> URL? {
        let tier = PlayerCardTierAssets.tierFolder(for: rank)
        let path = "\(tier)/\(layer.fileName)"
        return SupabaseConfig.publicStorageURL(bucket: bucket, path: path)
    }

    // MARK: - Cache

    private func cacheKey(for rank: PlayerCardRank, layer: PlayerCardLayer) -> String {
        "\(PlayerCardTierAssets.tierFolder(for: rank))/\(layer.rawValue)"
    }

    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("PlayerCardAssets", isDirectory: true)
    }

    private func diskURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key).appendingPathExtension("png")
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let url = diskURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(data: Data, key: String) {
        let url = diskURL(for: key)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
