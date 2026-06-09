import ComposableArchitecture
import SwiftUI

/// Achievement gallery: earned badges and pending ones with progress.
struct BadgesView: View {
    @Bindable var store: StoreOf<BadgesFeature>

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Insignias")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .onAppear { store.send(.onAppear) }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.badges.isEmpty {
            LoadingView()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    if !store.earned.isEmpty {
                        section("CONSEGUIDAS", badges: store.earned)
                    }
                    if !store.pending.isEmpty {
                        section("EN PROGRESO", badges: store.pending)
                    }
                    if let error = store.errorMessage {
                        AuthInlineMessage(text: error, kind: .error)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private func section(_ title: String, badges: [Badge]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)
            LazyVGrid(columns: columns, spacing: Theme.Spacing.small) {
                ForEach(badges) { badge in
                    badgeCell(badge)
                }
            }
        }
    }

    private func badgeCell(_ badge: Badge) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: badge.earned ? "rosette" : "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(badge.earned ? Theme.Colors.accent : Theme.Colors.textSecondary)
            Text(badge.title)
                .font(Theme.Typography.body(size: 15))
            Text(badge.description)
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !badge.earned {
                ProgressView(value: badge.progress)
                    .tint(Theme.Colors.accent)
                Text("\(Int(min(badge.current, badge.target)))/\(Int(badge.target))")
                    .font(Theme.Typography.caption(size: 10))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(badge.earned ? Theme.Colors.accent.opacity(0.4) : .clear, lineWidth: 1)
        )
        .opacity(badge.earned ? 1 : 0.75)
    }
}
