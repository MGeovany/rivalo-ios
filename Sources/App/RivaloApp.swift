import ComposableArchitecture
import PostHog
import SwiftUI

@main
struct RivaloApp: App {
    /// The single root store for the whole app.
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        Theme.registerFonts()
        MatchNotifications.shared.bootstrap()

        let config = PostHogConfig(
            apiKey: PostHogEnv.projectToken,
            host: PostHogEnv.host
        )
        config.captureApplicationLifecycleEvents = true
        config.errorTrackingConfig.autoCapture = true
        config.sessionReplay = true
        config.sessionReplayConfig.screenshotMode = true
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = true
        config.sessionReplayConfig.captureLogs = true
        PostHogSDK.shared.setup(config)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
                .preferredColorScheme(.dark)
        }
    }
}
