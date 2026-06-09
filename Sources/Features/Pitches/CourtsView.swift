import ComposableArchitecture
import SwiftUI

/// Courts management: list of saved courts with create/edit/delete.
struct CourtsView: View {
    @Bindable var store: StoreOf<CourtsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Canchas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addTapped) } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.Colors.accent)
                }
            }
            .onAppear { store.send(.onAppear) }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .sheet(item: $store.scope(state: \.edit, action: \.edit)) { editStore in
            CourtEditView(store: editStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.pitches.isEmpty {
            LoadingView()
        } else if store.pitches.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.small) {
                    ForEach(store.pitches) { pitch in
                        Button { store.send(.courtTapped(pitch)) } label: {
                            courtRow(pitch)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private func courtRow(_ pitch: Pitch) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(pitch.name)
                    .font(Theme.Typography.body(size: 16))
                Text(subtitle(pitch))
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func subtitle(_ pitch: Pitch) -> String {
        var parts: [String] = []
        if let type = pitch.type { parts.append(type) }
        if let surface = pitch.surface { parts.append(surface) }
        if pitch.indoor == true { parts.append("Interior") }
        if let dim = pitch.dimensionsText { parts.append(dim) }
        return parts.isEmpty ? "Toca para añadir detalles" : parts.joined(separator: " · ")
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "sportscourt")
                .font(.system(size: 32))
                .foregroundStyle(Theme.Colors.accent)
            Text("Sin canchas aún")
                .font(Theme.Typography.title(size: 20))
            Text("Añade los lugares donde juegas para comparar sesiones y llevar registro de tus canchas.")
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button { store.send(.addTapped) } label: {
                Label("Añadir cancha", systemImage: "plus")
                    .font(Theme.Typography.button())
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Spacing.xl)
    }
}
