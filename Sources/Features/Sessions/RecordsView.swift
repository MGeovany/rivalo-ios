import ComposableArchitecture
import SwiftUI

struct RecordsView: View {
    @Bindable var store: StoreOf<RecordsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading, store.records.isEmpty {
                    loadingState
                } else if let error = store.errorMessage, store.records.isEmpty {
                    errorState(error)
                } else if store.records.isEmpty {
                    emptyState
                } else {
                    recordsContent
                }
            }
            .rivalNavigationChrome(title: "Personal Records")
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ProgressView()
                .tint(Theme.Colors.accent)
            Text("Loading records…")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.large) {
            Text(message)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") { store.send(.onAppear) }
                .font(Theme.Typography.button())
                .foregroundStyle(Color.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
        }
        .padding(Theme.Spacing.xl)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.accentBright.opacity(0.3), Theme.Colors.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            Text("No records yet")
                .font(Theme.Typography.title(size: 22))
            Text("Complete a match to start tracking personal bests.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var recordsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                RecordsHeroBanner(count: store.records.count)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: Theme.Spacing.medium),
                        GridItem(.flexible(), spacing: Theme.Spacing.medium),
                    ],
                    spacing: Theme.Spacing.medium
                ) {
                    ForEach(store.records) { record in
                        RecordMetricCard(record: record)
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

// MARK: - Home promo

/// Tappable card on Home that previews top records.
struct PersonalRecordsHomeCard: View {
    let highlights: [RecordEntry]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.07, blue: 0.02),
                                Theme.Colors.surface,
                                Theme.Colors.background,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PERSONAL RECORDS")
                                .font(Theme.Typography.statLabel(size: 10))
                                .foregroundStyle(Theme.Colors.accentBright.opacity(0.95))
                                .tracking(1.2)

                            Text("Your best marks")
                                .font(Theme.Typography.body(size: 15))
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }

                        Spacer(minLength: 0)

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    if highlights.isEmpty {
                        Text("Tap to view all categories")
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } else {
                        HStack(spacing: Theme.Spacing.small) {
                            ForEach(highlights.prefix(3)) { record in
                                RecordHighlightChip(record: record)
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        Text("View all")
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.accent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .padding(Theme.Spacing.large)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accentBright.opacity(0.55),
                                Theme.Colors.accent.opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecordHighlightChip: View {
    let record: RecordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(record.formattedValue)
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(record.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(record.label)
                .font(Theme.Typography.statLabel(size: 8))
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Records screen

private struct RecordsHeroBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "medal.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accentBright, Theme.Colors.accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) personal bests")
                    .font(Theme.Typography.title(size: 18))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Across all tracked categories")
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.accent.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.Colors.accent.opacity(0.25), lineWidth: 1)
                }
        )
    }
}

private struct RecordMetricCard: View {
    let record: RecordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(record.accentColor.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: record.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(record.accentColor)
                }
                Spacer(minLength: 0)
                Text("PR")
                    .font(Theme.Typography.statLabel(size: 8))
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.35))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 1, green: 0.75, blue: 0.2).opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(record.formattedValue)
                .font(Theme.Typography.metric(size: 24))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(record.label.uppercased())
                .font(Theme.Typography.statLabel(size: 9))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.6)

            Text(record.startedAt.formatted(date: .abbreviated, time: .omitted))
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.8))
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.surface, Color(red: 0.1, green: 0.1, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [record.accentColor.opacity(0.5), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

#Preview {
    RecordsView(
        store: Store(
            initialState: RecordsFeature.State(
                accessToken: "preview",
                records: [
                    RecordEntry(metric: "distance_m", value: 12500, sessionId: "1", startedAt: Date().addingTimeInterval(-86400)),
                    RecordEntry(metric: "duration_s", value: 5400, sessionId: "2", startedAt: Date().addingTimeInterval(-172800)),
                    RecordEntry(metric: "speed_max_kmh", value: 29.3, sessionId: "3", startedAt: Date().addingTimeInterval(-259200)),
                ]
            )
        ) {
            RecordsFeature()
        }
    )
}
