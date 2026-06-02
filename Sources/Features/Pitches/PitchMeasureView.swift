import ComposableArchitecture
import SwiftUI

struct PitchMeasureView: View {
    @Bindable var store: StoreOf<PitchMeasureFeature>

    var body: some View {
        NavigationStack {
            Group {
                switch store.route {
                case .hub:
                    hubContent
                case .walk:
                    PitchWalkMeasureView(onBack: { store.send(.backToHub) })
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { store.send(.dismissTapped) }
                }
            }
        }
    }

    private var navigationTitle: String {
        switch store.route {
        case .hub: "Measure court"
        case .walk: "Run the pitch"
        }
    }

    private var hubContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Text("Save pitch size to compare sessions at the same place.")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)

                ForEach(PitchMeasurementMethod.iphoneHubCases) { method in
                    methodCard(method)
                }

                HStack(spacing: Theme.Spacing.medium) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manual on Apple Watch")
                            .font(Theme.Typography.title(size: 16))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Set length and width with +/− on your watch. Courts get a default name from the date and time.")
                            .font(Theme.Typography.body(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(Theme.Spacing.large)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
    }

    private func methodCard(_ method: PitchMeasurementMethod) -> some View {
        Button {
            store.send(.methodSelected(method))
        } label: {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: method.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(Theme.Typography.title(size: 18))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(method.subtitle)
                        .font(Theme.Typography.body(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                    Text(method.deviceHint)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.accent.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.large)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
