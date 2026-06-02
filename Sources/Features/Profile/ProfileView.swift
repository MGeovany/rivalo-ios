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
                                PlayerProgressCard(
                                    model: card,
                                    isPhotoAdjustable: store.canAdjustCardPhoto,
                                    onPhotoPlacementChange: { store.send(.photoPlacementChanged($0)) }
                                )

                                if store.profile != nil {
                                    ProfileCardPhotoControls(
                                        hasPhoto: store.hasCardPhoto,
                                        isProcessing: store.isProcessingPhoto,
                                        showsFixButton: store.showsPhotoFixButton,
                                        isPlacementLocked: store.isPhotoPlacementLocked,
                                        onPhotoData: { store.send(.photoSelected($0)) },
                                        onRemove: { store.send(.photoRemoved) },
                                        onFixPhoto: { store.send(.photoFixTapped) },
                                        onAdjust: { store.send(.photoAdjustTapped) },
                                        onAdjustDone: { store.send(.photoAdjustFinished) }
                                    )
                                }
                            } else {
                                profileSetupHint
                            }

                            aboutCard
                            physicalCard

                            ProfilePrimaryButton(
                                title: "Save changes",
                                isEnabled: store.canSave,
                                isLoading: store.isSaving
                            ) {
                                store.send(.saveTapped)
                            }

                            Button { store.send(.courtsTapped) } label: {
                                HStack(spacing: Theme.Spacing.medium) {
                                    Image(systemName: "sportscourt.fill")
                                        .foregroundStyle(Theme.Colors.accent)
                                    Text("Manage courts")
                                        .font(Theme.Typography.body(size: 16))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                                .padding(Theme.Spacing.medium)
                                .frame(maxWidth: .infinity)
                                .background(Theme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                            }
                            .buttonStyle(.plain)

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
        .rivalToast(message: store.errorMessage, kind: .error) {
            store.send(.errorDismissed)
        }
        .onAppear { store.send(.onAppear) }
        .refreshable { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.courts, action: \.courts)) { courtsStore in
            CourtsView(store: courtsStore)
        }
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

                ProfileBirthDatePicker(date: $store.birthDate)
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
