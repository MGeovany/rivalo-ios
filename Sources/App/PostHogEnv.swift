import Foundation

enum PostHogEnv {
    static var projectToken: String {
        value(forKey: "PostHogProjectToken", envKey: "POSTHOG_PROJECT_TOKEN")
    }

    static var host: String {
        value(forKey: "PostHogHost", envKey: "POSTHOG_HOST")
    }

    private static func value(forKey plistKey: String, envKey: String) -> String {
        if let bundled = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String,
           !bundled.isEmpty {
            return bundled
        }
        if let env = ProcessInfo.processInfo.environment[envKey], !env.isEmpty {
            return env
        }
        fatalError("Missing PostHog config: add \(plistKey) to Info.plist or set \(envKey) in the scheme.")
    }
}
