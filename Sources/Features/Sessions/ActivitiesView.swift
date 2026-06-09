import ComposableArchitecture
import SwiftUI

/// Full activity history (moved off Home).
struct ActivitiesView: View {
    @Bindable var store: StoreOf<SessionsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Actividades")
            .onAppear { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
        .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            SessionDetailView(store: detailStore)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.sessions.isEmpty {
            VStack(spacing: Theme.Spacing.medium) {
                ProgressView()
                    .tint(Theme.Colors.accent)
                Text("Cargando actividades…")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        } else if store.sessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    ActivitiesSearchBar(
                        text: $store.activitySearchText,
                        filter: $store.activityFilter,
                        resultCount: store.filteredActivities.count
                    )

                    if store.filteredActivities.isEmpty {
                        filteredEmptyState
                    } else {
                        LazyVStack(spacing: Theme.Spacing.medium) {
                            ForEach(store.filteredActivities) { session in
                                Button { store.send(.sessionTapped(session)) } label: {
                                    ActivityListRow(
                                        session: session,
                                        meta: SessionMetaStore.load(sessionId: session.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .refreshable { store.send(.onAppear) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "figure.run")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            Text("Sin actividades aún")
                .font(Theme.Typography.title(size: 20))
            Text("Tus partidos registrados aparecen aquí.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.6))
            Text("Sin resultados")
                .font(Theme.Typography.body(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Prueba otra búsqueda o filtro.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - Search & filters

private struct ActivitiesSearchBar: View {
    @Binding var text: String
    @Binding var filter: ActivityListFilter
    let resultCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)

                TextField("Buscar cancha, tipo, resultado…", text: $text)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.textSecondary.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent.opacity(text.isEmpty ? 0.15 : 0.45),
                                Color.white.opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(ActivityListFilter.allCases) { option in
                        ActivitiesFilterChip(
                            title: option.rawValue,
                            isSelected: filter == option
                        ) {
                            filter = option
                        }
                    }
                }
            }

            Text("\(resultCount) \(resultCount == 1 ? "partido" : "partidos")")
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

private struct ActivitiesFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(isSelected ? Color.black : Theme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    }
                }
                .overlay {
                    if !isSelected {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity row

/// Modern activity card for the Activities tab.
struct ActivityListRow: View {
    let session: SportSession
    let meta: SessionMeta

    private var headlineDate: String {
        session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var headlineTime: String {
        session.startedAt.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 0) {
                Text(headlineDate.uppercased())
                    .font(Theme.Typography.statLabel(size: 9))
                    .foregroundStyle(Theme.Colors.accentBright.opacity(0.9))
                    .tracking(0.8)
                Text(headlineTime)
                    .font(Theme.Typography.metric(size: 22))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .frame(width: 72, alignment: .leading)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accentBright, Theme.Colors.accent.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(SessionActivityGeometry.displayLocation(session: session, meta: meta))
                        .font(Theme.Typography.body(size: 15))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let rating = session.matchRating {
                        Text(String(format: "%.0f", rating))
                            .font(Theme.Typography.statLabel(size: 11))
                            .foregroundStyle(Theme.Colors.accentBright)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.accent.opacity(0.18))
                            .clipShape(Capsule())
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary.opacity(0.45))
                }

                if let context = contextSubtitle {
                    Text(context)
                        .font(Theme.Typography.caption(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 0) {
                    statColumn(String(format: "%.2f", session.distanceM / 1000), "km")
                    statDivider
                    statColumn("\(session.durationS / 60)", "min")
                    statDivider
                    statColumn("\(session.sprints)", "sprints")
                    if let hr = session.hrAvg {
                        statDivider
                        statColumn("\(hr)", "bpm")
                    }
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.13),
                            Theme.Colors.surface,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var contextSubtitle: String? {
        var parts: [String] = []
        if let matchType = session.matchType { parts.append(matchType) }
        if let result = session.result { parts.append(result) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
            .padding(.horizontal, 10)
    }

    private func statColumn(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.Typography.statLabel(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .textCase(.uppercase)
        }
    }
}
