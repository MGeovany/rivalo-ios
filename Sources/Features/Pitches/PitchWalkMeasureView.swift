import SwiftUI

/// V2-F walk measurement on iPhone (CoreLocation). Full capture ships in F.4.
struct PitchWalkMeasureView: View {
    var onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Label("GPS measurement", systemImage: "location.fill")
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Run along one goal line, tap Done, then run the sideline. Rivalo adds length and width from GPS.")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    stepRow(1, "Start length — jog with the phone in your pocket or armband")
                    stepRow(2, "Finish length — note the distance")
                    stepRow(3, "Repeat for width along the touchline")
                }

                Text("You can also measure on your Apple Watch: Measure court → Run the pitch.")
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Button("Coming soon on iPhone") {}
                    .font(Theme.Typography.button(size: 16))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.Colors.surface)
                    .clipShape(Capsule())
                    .disabled(true)

                Button("Back to methods", action: onBack)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Text("\(number)")
                .font(Theme.Typography.statLabel(size: 12))
                .foregroundStyle(Color.black)
                .frame(width: 22, height: 22)
                .background(Theme.Colors.accent)
                .clipShape(Circle())
            Text(text)
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}
