import ComposableArchitecture
import SwiftUI

struct RecordsView: View {
    @Bindable var store: StoreOf<RecordsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading {
                    ProgressView("Loading records...")
                } else if let error = store.errorMessage {
                    VStack(spacing: 12) {
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") { store.send(.onAppear) }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                } else if store.records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text("No records yet")
                            .font(Theme.Typography.title(size: 20))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Complete a match to start tracking your personal bests.")
                            .font(Theme.Typography.body(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(store.records) { record in
                                recordRow(record)
                                if record.metric != store.records.last?.metric {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(Theme.Colors.surface)
                        .cornerRadius(14)
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.top, 8)
                    }
                }
            }
            .rivalNavigationChrome(title: "Personal Records")
            .task { store.send(.onAppear) }
        }
        .tint(Theme.Colors.accent)
    }

    private func recordRow(_ record: RecordEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: record.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.label)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(record.startedAt, style: .date)
                    .font(Theme.Typography.caption(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(record.formattedValue)
                .font(Theme.Typography.title(size: 18))
                .foregroundStyle(Theme.Colors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
