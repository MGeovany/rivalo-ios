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
                                PlayerProgressCard(model: card)
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

                            profileRow(title: "Manage courts", icon: "sportscourt.fill") {
                                store.send(.courtsTapped)
                            }
                            profileRow(title: "Badges", icon: "rosette") {
                                store.send(.badgesTapped)
                            }
                            profileRow(title: "Rivalries", icon: "person.2.fill") {
                                store.send(.rivalriesTapped)
                            }
                            profileRow(title: "Goals", icon: "target") {
                                store.send(.goalsTapped)
                            }
                            profileRow(title: "Dev: API Status", icon: "antenna.radiowaves.left.and.right") {
                                store.send(.devTapped)
                            }

                            ProfileSignOutButton {
                                store.send(.signOutTapped)
                            }

                            ProfileDeleteAccountButton(isLoading: store.isDeletingAccount) {
                                store.send(.deleteAccountTapped)
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
        .alert(
            "Delete account",
            isPresented: Binding(
                get: { store.isDeleteAccountAlertShown },
                set: { if !$0 { store.send(.deleteAccountCancelled) } }
            )
        ) {
            Button("Delete", role: .destructive) { store.send(.deleteAccountConfirmed) }
            Button("Cancel", role: .cancel) { store.send(.deleteAccountCancelled) }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone.")
        }
        .rivalToast(message: store.errorMessage, kind: .error) {
            store.send(.errorDismissed)
        }
        .onAppear { store.send(.onAppear) }
        .refreshable { store.send(.onAppear) }
        .sheet(item: $store.scope(state: \.courts, action: \.courts)) { courtsStore in
            CourtsView(store: courtsStore)
        }
        .sheet(item: $store.scope(state: \.badges, action: \.badges)) { badgesStore in
            BadgesView(store: badgesStore)
        }
        .sheet(item: $store.scope(state: \.rivalries, action: \.rivalries)) { rivalriesStore in
            RivalriesView(store: rivalriesStore)
        }
        .sheet(item: $store.scope(state: \.goals, action: \.goals)) { goalsStore in
            GoalsView(store: goalsStore)
        }
        .sheet(item: $store.scope(state: \.serverStatus, action: \.serverStatus)) { serverStatusStore in
            ServerStatusView(store: serverStatusStore)
        }
    }

    private func profileRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.accent)
                Text(title)
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
