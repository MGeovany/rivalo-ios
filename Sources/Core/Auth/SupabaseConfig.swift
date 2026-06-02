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
}
