import ComposableArchitecture
import SwiftUI

/// Top-level view. For Phase 1 it shows the server status screen; the tab bar
/// and feature navigation are introduced in later phases.
struct RootView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        ServerStatusView(
            store: store.scope(state: \.serverStatus, action: \.serverStatus)
        )
    }
}
