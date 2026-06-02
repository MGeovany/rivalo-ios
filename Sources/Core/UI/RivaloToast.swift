import SwiftUI

/// Floating toast inspired by Sonner — compact card, slide from top, auto-dismiss friendly.
struct RivaloToast: View {
    enum Kind: Equatable {
        case error
        case success
        case info

        var icon: String {
            switch self {
            case .error: "exclamationmark.circle.fill"
            case .success: "checkmark.circle.fill"
            case .info: "info.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .error: Theme.Colors.negative
            case .success: Theme.Colors.positive
            case .info: Theme.Colors.accentBright
            }
        }

        var accentBorder: Color {
            switch self {
            case .error: Theme.Colors.negative.opacity(0.45)
            case .success: Theme.Colors.positive.opacity(0.4)
            case .info: Theme.Colors.accent.opacity(0.4)
            }
        }
    }

    let message: String
    let kind: Kind
    var onDismiss: (() -> Void)?

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(kind.iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: kind.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(kind.iconColor)
            }

            Text(message)
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(toastBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(kind.accentBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
        .offset(y: dragOffset)
        .gesture(dismissDrag)
    }

    private var toastBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.16, blue: 0.17),
                        Theme.Colors.surface,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragOffset = min(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height < -24 {
                    onDismiss?()
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    dragOffset = 0
                }
            }
    }
}

extension View {
    /// Presents a Sonner-style toast when `message` is non-nil.
    func rivalToast(
        message: String?,
        kind: RivaloToast.Kind = .error,
        onDismiss: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .top) {
            if let message {
                RivaloToast(message: message, kind: kind, onDismiss: onDismiss)
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.top, Theme.Spacing.small)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.96)),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: message)
    }
}
