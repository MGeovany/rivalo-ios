import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        TabView(selection: tabSelection) {
            SessionsView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Sessions", systemImage: "figure.run") }
                .tag(MainTabFeature.State.Tab.sessions)

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(MainTabFeature.State.Tab.profile)

            ServerStatusView(store: store.scope(state: \.serverStatus, action: \.serverStatus))
                .tabItem { Label("Status", systemImage: "bolt.heart.fill") }
                .tag(MainTabFeature.State.Tab.status)
        }
        .tint(Theme.Colors.accent)
        .task { store.send(.task) }
    }

    private var tabSelection: Binding<MainTabFeature.State.Tab> {
        Binding(
            get: { store.selectedTab },
            set: { store.send(.selectedTabChanged($0)) }
        )
    }
}
