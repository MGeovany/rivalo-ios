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
                                title: "Guardar cambios",
                                isEnabled: store.canSave,
                                isLoading: store.isSaving
                            ) {
                                store.send(.saveTapped)
                            }

                            profileRow(title: "Administrar canchas", icon: "sportscourt.fill") {
                                store.send(.courtsTapped)
                            }
                            profileRow(title: "Insignias", icon: "rosette") {
                                store.send(.badgesTapped)
                            }
                            profileRow(title: "Rivalidades", icon: "person.2.fill") {
                                store.send(.rivalriesTapped)
                            }
                            profileRow(title: "Objetivos", icon: "target") {
                                store.send(.goalsTapped)
                            }
                            profileRow(title: "Dev: Estado API", icon: "antenna.radiowaves.left.and.right") {
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
            .rivalNavigationChrome(title: "Tú")
        }
        .tint(Theme.Colors.accent)
        .foregroundStyle(Theme.Colors.textPrimary)
        .alert(
            "Eliminar cuenta",
            isPresented: Binding(
                get: { store.isDeleteAccountAlertShown },
                set: { if !$0 { store.send(.deleteAccountCancelled) } }
            )
        ) {
            Button("Eliminar", role: .destructive) { store.send(.deleteAccountConfirmed) }
            Button("Cancelar", role: .cancel) { store.send(.deleteAccountCancelled) }
        } message: {
            Text("Esto eliminará permanentemente tu cuenta y todos tus datos. Esta acción no se puede deshacer.")
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
            Text("Guarda tu perfil para desbloquear tu tarjeta de jugador")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.medium)
    }

    private var aboutCard: some View {
        ProfileSectionCard(title: "Sobre ti") {
            VStack(spacing: Theme.Spacing.large) {
                ProfileFieldRow(
                    icon: "person.fill",
                    label: "Nombre visible",
                    text: $store.displayName,
                    placeholder: "Cómo te ven tus compañeros",
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
        ProfileSectionCard(title: "Físico") {
            VStack(spacing: Theme.Spacing.large) {
                ProfileMetricField(
                    label: "Altura",
                    text: $store.heightText,
                    unit: store.heightUnit,
                    unitLabel: { $0.menuLabel },
                    onUnitChange: { store.send(.heightUnitChanged($0)) },
                    keyboard: heightKeyboard
                )

                ProfileMetricField(
                    label: "Peso",
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
