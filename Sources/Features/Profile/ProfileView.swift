import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if store.isLoading && store.profile == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.xl) {
                            if let card = store.playerCard {
                                FIFAPlayerCard(model: card)

                                if store.profile != nil {
                                    ProfileCardPhotoControls(
                                        hasPhoto: store.hasCardPhoto,
                                        onPhotoData: { store.send(.photoSelected($0)) },
                                        onRemove: { store.send(.photoRemoved) }
                                    )
                                }
                            } else {
                                profileSetupHint
                            }

                            aboutCard
                            physicalCard

                            if let message = store.errorMessage {
                                AuthInlineMessage(text: message, kind: .error)
                            }

                            ProfilePrimaryButton(
                                title: "Save changes",
                                isEnabled: store.canSave,
                                isLoading: store.isSaving
                            ) {
                                store.send(.saveTapped)
                            }

                            ProfileSignOutButton {
                                store.send(.signOutTapped)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.top, Theme.Spacing.medium)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .rivalNavigationChrome(title: "You")
        }
        .tint(Theme.Colors.accent)
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
        .refreshable { store.send(.onAppear) }
    }

    // MARK: - Sections

    private var profileSetupHint: some View {
        VStack(spacing: Theme.Spacing.small) {
            ProfileAvatarView(initials: ProfileFormatting.initials(from: store.displayName))
            Text("Save your profile to unlock your player card")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.medium)
    }

    private var aboutCard: some View {
        ProfileSectionCard(title: "About you") {
            VStack(spacing: Theme.Spacing.large) {
                ProfileFieldRow(
                    icon: "person.fill",
                    label: "Display name",
                    text: $store.displayName,
                    placeholder: "How teammates see you",
                    textContentType: .name
                )

                ProfileCountrySelect(code: store.countryCode) { code in
                    store.send(.countryCodeChanged(code))
                }

                ProfilePositionSelect(selection: $store.preferredPosition)
            }
        }
    }

    private var physicalCard: some View {
        ProfileSectionCard(title: "Physical") {
            VStack(spacing: Theme.Spacing.large) {
                ProfileMetricField(
                    label: "Height",
                    text: $store.heightText,
                    unit: store.heightUnit,
                    unitLabel: { $0.menuLabel },
                    onUnitChange: { store.send(.heightUnitChanged($0)) },
                    keyboard: heightKeyboard
                )

                ProfileMetricField(
                    label: "Weight",
                    text: $store.weightText,
                    unit: store.weightUnit,
                    unitLabel: { $0.menuLabel },
                    onUnitChange: { store.send(.weightUnitChanged($0)) },
                    keyboard: .decimalPad
                )
            }
        }
    }

    private var heightKeyboard: UIKeyboardType {
        store.heightUnit == .centimeters ? .numberPad : .decimalPad
    }

}

#Preview {
    ProfileView(
        store: Store(
            initialState: ProfileFeature.State(
                accessToken: "preview",
                profile: Profile(
                    id: "preview-id",
                    displayName: "Alex Rivera",
                    preferredPosition: "Midfielder",
                    heightCm: 178,
                    weightKg: 72
                ),
                displayName: "Alex Rivera",
                preferredPosition: "Midfielder",
                heightText: "178",
                weightText: "72"
            )
        ) {
            ProfileFeature()
        }
    )
}
