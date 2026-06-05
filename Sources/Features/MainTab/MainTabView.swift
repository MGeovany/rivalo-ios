import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        TabView(selection: tabSelection) {
            SessionsView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(MainTabFeature.State.Tab.home)

            ActivitiesView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Activities", systemImage: "figure.run") }
                .tag(MainTabFeature.State.Tab.activities)

            RecordView(store: store.scope(state: \.record, action: \.record))
                .tabItem { Label("Record", systemImage: "record.circle") }
                .tag(MainTabFeature.State.Tab.record)

            InsightsView(store: store.scope(state: \.insights, action: \.insights))
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(MainTabFeature.State.Tab.insights)

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(MainTabFeature.State.Tab.you)
        }
        .tint(Theme.Colors.accent)
        .task { store.send(.task) }
        #if DEBUG
        .overlay(alignment: .top) {
            WatchDebugOverlay()
                .padding(.top, 52)
        }
        #endif
    }

    private var tabSelection: Binding<MainTabFeature.State.Tab> {
        Binding(
            get: { store.selectedTab },
            set: { store.send(.selectedTabChanged($0)) }
        )
    }
}
