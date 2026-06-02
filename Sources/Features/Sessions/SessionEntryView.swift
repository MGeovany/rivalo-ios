import ComposableArchitecture
import SwiftUI

struct SessionEntryView: View {
    @Bindable var store: StoreOf<SessionEntryFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.medium) {
                        field("Duration (min)", text: $store.durationMin, keyboard: .numberPad)
                        field("Distance (km)", text: $store.distanceKm, keyboard: .decimalPad)
                        field("Avg heart rate", text: $store.hrAvg, keyboard: .numberPad)
                        field("Max heart rate", text: $store.hrMax, keyboard: .numberPad)
                        field("Sprints", text: $store.sprints, keyboard: .numberPad)
                        field("Intensity (0-100)", text: $store.intensity, keyboard: .decimalPad)

                        if let message = store.errorMessage {
                            Text(message)
                                .font(Theme.Typography.caption())
                                .foregroundStyle(Theme.Colors.negative)
                        }

                        submitButton
                    }
                    .padding(Theme.Spacing.large)
                }
            }
            .navigationTitle("New session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { store.send(.cancelTapped) }
                        .tint(Theme.Colors.textSecondary)
                }
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(label)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
            TextField("", text: text)
                .keyboardType(keyboard)
                .padding()
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private var submitButton: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button { store.send(.submitTapped) } label: {
                ZStack {
                    if store.isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        Text("Save session").font(Theme.Typography.button())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.canSubmit ? Theme.Colors.accent : Theme.Colors.surface)
                .foregroundStyle(store.canSubmit ? Color.black : Theme.Colors.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .disabled(!store.canSubmit || store.isSubmitting)

            if store.isSubmitting {
                CyclingLoadingMessage()
            }
        }
    }
}
