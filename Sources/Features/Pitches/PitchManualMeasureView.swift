import SwiftUI

/// manual dimensions saved to the backend with GPS when available.
struct PitchManualMeasureView: View {
    let accessToken: String
    var onBack: () -> Void

    @State private var name = ""
    @State private var lengthText = ""
    @State private var widthText = ""
    @State private var savedMessage: String?
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Text("Enter pitch size in meters. Saved with your account and synced to your watch.")
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

                Button(isSaving ? "Saving…" : "Save court") {
                    Task { await savePitch() }
                }
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave && !isSaving ? Theme.Colors.accent : Theme.Colors.surface)
                .clipShape(Capsule())
                .disabled(!canSave || isSaving)

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

    private func savePitch() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let length = Double(lengthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let width = Double(widthText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let courtName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await PitchesSync.create(
                accessToken: accessToken,
                apiClient: APIClient.liveValue,
                pitch: NewPitch(
                    name: courtName.isEmpty ? CourtDefaultName.make() : courtName,
                    latitude: nil,
                    longitude: nil,
                    lengthM: length,
                    widthM: width,
                    measurementMethod: PitchMeasurementMethod.manual.rawValue
                )
            )
            savedMessage = "Court saved. It will appear on your watch when you're nearby."
        } catch {
            savedMessage = "Could not save. Check your connection and try again."
        }
    }
}
