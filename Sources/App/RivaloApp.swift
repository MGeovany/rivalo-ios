import ComposableArchitecture
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
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
                .preferredColorScheme(.dark)
        }
    }
}
