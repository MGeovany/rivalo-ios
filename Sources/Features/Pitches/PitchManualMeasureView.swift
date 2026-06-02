import SwiftUI

/// V2-F manual dimensions (F.6). Persists locally until `/v1/pitches` ships.
struct PitchManualMeasureView: View {
    var onBack: () -> Void

    @State private var name = ""
    @State private var lengthText = ""
    @State private var widthText = ""
    @State private var savedMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Text("Enter pitch size in meters. You can correct these later.")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)

                field("Court name", text: $name)
                field("Length (m)", text: $lengthText, keyboard: .decimalPad)
                field("Width (m)", text: $widthText, keyboard: .decimalPad)

                if let savedMessage {
                    Text(savedMessage)
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.accent)
                }

                Button("Save locally") {
                    saveDraft()
                }
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? Theme.Colors.accent : Theme.Colors.surface)
                .clipShape(Capsule())
                .disabled(!canSave)

                Button("Back to methods", action: onBack)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
    }

    private var canSave: Bool {
        guard let length = Double(lengthText.replacingOccurrences(of: ",", with: ".")),
              let width = Double(widthText.replacingOccurrences(of: ",", with: ".")),
              length > 0, width > 0
        else { return false }
        return true
    }

    private func field(
        _ label: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .font(Theme.Typography.body(size: 16))
                .padding(Theme.Spacing.medium)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func saveDraft() {
        let courtName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = Double(lengthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let width = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        PitchDraftStore.save(
            PitchDraft(
                name: courtName.isEmpty ? "My court" : courtName,
                lengthM: length,
                widthM: width,
                measurementMethod: PitchMeasurementMethod.manual.rawValue
            )
        )
        savedMessage = "Saved on this iPhone. Backend sync arrives with V2-F API."
        WatchCourtSync.pushDraftCourts()
    }
}
