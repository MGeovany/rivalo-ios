import SwiftUI

// MARK: - Layout

/// Shared chrome for authentication screens (logo + title + content).
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
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                AuthLogo()

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(title)
                        .font(Theme.Typography.title(size: 26))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                content()

                footer()
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.top, Theme.Spacing.large)
            .padding(.bottom, Theme.Spacing.medium)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct AuthLogo: View {
    var body: some View {
        Text("RIVALO")
            .font(Theme.Typography.logo(size: 32))
            .tracking(8)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Controls

struct AuthTextField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)

            TextField("", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .textContentType(textContentType)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, 14)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

struct AuthSecureField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)

            SecureField("", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, 14)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(title)
                        .font(Theme.Typography.button(size: 17))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Theme.Colors.accent : Theme.Colors.surface)
            .foregroundStyle(isEnabled ? Color.black : Theme.Colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct AuthLinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption())
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
        Text(text)
            .font(Theme.Typography.caption())
            .foregroundStyle(kind == .error ? Theme.Colors.negative : Theme.Colors.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.medium)
            .background(
                (kind == .error ? Theme.Colors.negative : Theme.Colors.accent)
                    .opacity(0.12)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
    }
}
