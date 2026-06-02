import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        TabView(selection: tabSelection) {
            SessionsView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(MainTabFeature.State.Tab.home)

            PlaceholderTabView(
                title: "Activities",
                headline: "Your activity feed",
                message: "Recent matches, effort trends, and highlights will show up here soon.",
                systemImage: "chart.line.uptrend.xyaxis"
            )
            .tabItem { Label("Activities", systemImage: "figure.run") }
            .tag(MainTabFeature.State.Tab.activities)

            RecordView(store: store.scope(state: \.record, action: \.record))
                .tabItem { Label("Record", systemImage: "record.circle") }
                .tag(MainTabFeature.State.Tab.record)

            PlaceholderTabView(
                title: "Plan",
                headline: "Match planning",
                message: "Weekly load, recovery, and pre-match prep — coming in a future update.",
                systemImage: "calendar"
            )
            .tabItem { Label("Plan", systemImage: "list.clipboard") }
            .tag(MainTabFeature.State.Tab.plan)

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(MainTabFeature.State.Tab.you)
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
