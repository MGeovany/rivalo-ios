import ComposableArchitecture
import SwiftUI

/// Top-level view: shows a splash while restoring the session, then routes to
/// the tab bar when signed in or the authentication flow otherwise.
struct RootView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isLoading {
                SplashView()
            } else if let mainStore = store.scope(state: \.main, action: \.main) {
                MainTabView(store: mainStore)
            } else {
                AuthenticationView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
