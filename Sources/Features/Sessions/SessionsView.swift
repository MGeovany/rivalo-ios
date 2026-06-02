import ComposableArchitecture
import SwiftUI

struct SessionsView: View {
    @Bindable var store: StoreOf<SessionsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addTapped) } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.Colors.accent)
                }
            }
        }
        .tint(Theme.Colors.accent)
        .onAppear { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.entry, action: \.entry)) { entryStore in
            SessionEntryView(store: entryStore)
        }
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            SessionDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            ProgressView().tint(Theme.Colors.accent)
        } else if store.sessions.isEmpty {
            VStack(spacing: Theme.Spacing.small) {
                Text("No sessions yet")
                    .font(Theme.Typography.title())
                Text("Tap + to add a manual session")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.medium) {
                    ForEach(store.sessions) { session in
                        Button { store.send(.sessionTapped(session)) } label: {
                            row(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.large)
            }
        }
    }

    private func row(_ session: SportSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Typography.body())
                Text(session.source.capitalized)
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.durationText)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.accent)
                Text(session.distanceKmText)
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}
