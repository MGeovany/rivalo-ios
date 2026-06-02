import Foundation

/// Static configuration for talking to Supabase Auth. Values are injected via
/// the Info.plist (set from build settings). The anon key is a public client
/// key by design and safe to ship in the app.
enum SupabaseConfig {
    static var url: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
        return URL(string: raw) ?? URL(string: "https://invalid.supabase.co")!
    }

    static var anonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
    }

    /// Public object URL for Supabase Storage (`/storage/v1/object/public/...`).
    static func publicStorageURL(bucket: String, path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        return url
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(trimmed)
    }
}
