import SwiftUI

// MARK: - Layout

/// Shared chrome for authentication screens — centered, airy, minimal.
struct AuthScreenLayout<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.footer = footer
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                AuthHeader()

                VStack(spacing: Theme.Spacing.small) {
                    Text(title)
                        .font(Theme.Typography.title(size: 30))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.body(size: 15))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }

                content()

                footer()
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, 48)
            .padding(.bottom, Theme.Spacing.xl)
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct AuthHeader: View {
    var body: some View {
        BrandLogo(style: .isotipo, height: 52)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Controls

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        TextField("", text: $text, prompt: prompt)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .font(Theme.Typography.body(size: 17))
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.Colors.textSecondary.opacity(0.35))
                    .frame(height: 1)
            }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Group {
                if isRevealed {
                    TextField("", text: $text, prompt: prompt)
                } else {
                    SecureField("", text: $text, prompt: prompt)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.password)
            .font(Theme.Typography.body(size: 17))
            .foregroundStyle(Theme.Colors.textPrimary)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRevealed ? "Ocultar contraseña" : "Mostrar contraseña")
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.Colors.textSecondary.opacity(0.35))
                .frame(height: 1)
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(Theme.Colors.textSecondary.opacity(0.85))
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button(action: action) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text(title)
                            .font(Theme.Typography.button(size: 17))
                            .foregroundStyle(Color.black.opacity(isEnabled ? 1 : 0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Colors.accent.opacity(isEnabled ? 1 : 0.35))
                .clipShape(Capsule())
            }
            .disabled(!isEnabled || isLoading)

            if isLoading {
                CyclingLoadingMessage()
            }
        }
        .padding(.top, Theme.Spacing.small)
    }
}

struct AuthLinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.button(size: 15))
                .foregroundStyle(Theme.Colors.accent)
        }
        .buttonStyle(.plain)
    }
}

struct AuthInlineMessage: View {
    enum Kind { case error, info }

    let text: String
    let kind: Kind

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            RoundedRectangle(cornerRadius: 2)
                .fill(kind == .error ? Theme.Colors.negative : Theme.Colors.accent)
                .frame(width: 3)

            Text(text)
                .font(Theme.Typography.caption())
                .foregroundStyle(kind == .error ? Theme.Colors.negative : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.Spacing.small)
    }
}

struct AuthHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthFooterLink: View {
    let prefix: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(prefix)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
            AuthLinkButton(title: actionTitle, action: action)
        }
        .frame(maxWidth: .infinity)
    }
}
