import SwiftUI

/// Counts up to a numeric target with a smooth spring animation.
struct AnimatedMetricText: View {
    enum Format: Equatable {
        case decimal(fractionDigits: Int)
        case integer
    }

    let value: Double?
    let format: Format
    var placeholder: String = "—"

    @State private var displayed: Double = 0
    @State private var hasAppeared = false

    var body: some View {
        Group {
            if let value {
                Text(formatted(displayed))
                    .contentTransition(.numericText(value: displayed))
            } else {
                Text(placeholder)
            }
        }
        .onAppear {
            guard let value else { return }
            if hasAppeared {
                displayed = value
            } else {
                displayed = 0
                hasAppeared = true
                withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                    displayed = value
                }
            }
        }
        .onChange(of: value) { _, newValue in
            guard let newValue else {
                displayed = 0
                return
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
                displayed = newValue
            }
        }
    }

    private func formatted(_ number: Double) -> String {
        switch format {
        case let .decimal(fractionDigits):
            String(format: "%.\(fractionDigits)f", number)
        case .integer:
            String(Int(number.rounded()))
        }
    }
}
