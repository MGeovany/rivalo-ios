import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            if store.isLoading && store.profile == nil {
                LoadingView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                        header

                        VStack(spacing: Theme.Spacing.medium) {
                            labeledField("Display name", text: $store.displayName)
                            labeledField("Preferred position", text: $store.preferredPosition, placeholder: "e.g. midfielder")
                            labeledField("Height (cm)", text: $store.heightText, keyboard: .numberPad)
                            labeledField("Weight (kg)", text: $store.weightText, keyboard: .decimalPad)
                        }

                        if let message = store.errorMessage {
                            Text(message)
                                .font(Theme.Typography.caption())
                                .foregroundStyle(Theme.Colors.negative)
                        }

                        saveButton
                        signOutButton
                    }
                    .padding(Theme.Spacing.large)
                }
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profile")
                .font(Theme.Typography.title())
            if let id = store.profile?.id {
                Text(id)
                    .font(Theme.Typography.statLabel())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private func labeledField(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(label)
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.textSecondary))
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .padding()
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private var saveButton: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button {
                store.send(.saveTapped)
            } label: {
                ZStack {
                    if store.isSaving {
                        ProgressView().tint(.black)
                    } else {
                        Text("Save").font(Theme.Typography.button())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.canSave ? Theme.Colors.accent : Theme.Colors.surface)
                .foregroundStyle(store.canSave ? Color.black : Theme.Colors.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .disabled(!store.canSave || store.isSaving)

            if store.isSaving {
                CyclingLoadingMessage()
            }
        }
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            store.send(.signOutTapped)
        } label: {
            Text("Sign out")
                .font(Theme.Typography.button())
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(Theme.Colors.negative)
        }
    }
}

#Preview {
    ProfileView(
        store: Store(initialState: ProfileFeature.State(accessToken: "preview")) {
            ProfileFeature()
        }
    )
}
