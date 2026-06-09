import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        TabView(selection: tabSelection) {
            SessionsView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(MainTabFeature.State.Tab.home)

            ActivitiesView(store: store.scope(state: \.sessions, action: \.sessions))
                .tabItem { Label("Actividades", systemImage: "figure.run") }
                .tag(MainTabFeature.State.Tab.activities)

            RecordView(store: store.scope(state: \.record, action: \.record))
                .tabItem { Label("Grabar", systemImage: "record.circle") }
                .tag(MainTabFeature.State.Tab.record)

            InsightsView(store: store.scope(state: \.insights, action: \.insights))
                .tabItem { Label("Estadísticas", systemImage: "chart.bar.fill") }
                .tag(MainTabFeature.State.Tab.insights)

            ProfileView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("Tú", systemImage: "person.fill") }
                .tag(MainTabFeature.State.Tab.you)
        }
        .tint(Theme.Colors.accent)
        .task { store.send(.task) }
        #if DEBUG
        .overlay(alignment: .top) {
            WatchDebugOverlay()
                .padding(.top, 52)
                // Purely informational — must never absorb taps meant for the UI
                // beneath it (e.g. the post-match form's Skip/Save toolbar).
                .allowsHitTesting(false)
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
