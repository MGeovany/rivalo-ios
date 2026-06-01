import Foundation

/// Static configuration for talking to the backend API.
enum APIConfig {
    /// Base URL of the backend. Read from the Info.plist key `RivaloAPIBaseURL`
    /// (injected per build configuration), falling back to the local server.
    static var baseURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "RivaloAPIBaseURL") as? String,
           let url = URL(string: raw) {
            return url
        }
        return URL(string: "http://localhost:8080")!
    }
}
