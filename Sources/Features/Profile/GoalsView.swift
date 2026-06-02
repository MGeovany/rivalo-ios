import ComposableArchitecture
import SwiftUI

struct GoalsView: View {
    @Bindable var store: StoreOf<GoalsFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Goals")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { store.send(.dismissTapped) }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+ New") { store.send(.newGoalTapped) }
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .onAppear { store.send(.onAppear) }
            .sheet(isPresented: Binding(
                get: { store.showNewForm },
                set: { if !$0 { store.send(.newGoalDismissed) } }
            )) {
                newGoalForm
            }
            .sheet(item: $store.scope(state: \.editGoal, action: \.editGoal)) { editStore in
                editGoalView(store: editStore)
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading, store.goals.isEmpty {
            LoadingView()
        } else if store.goals.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    if let error = store.errorMessage {
                        AuthInlineMessage(text: error, kind: .error)
                    }

                    if !store.active.isEmpty {
                        sectionTitle("ACTIVE")
                        ForEach(store.active) { goal in
                            goalCard(goal)
                        }
                    }

                    if !store.achieved.isEmpty {
                        sectionTitle("ACHIEVED")
                        ForEach(store.achieved) { goal in
                            goalCard(goal)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("No goals yet")
                .font(Theme.Typography.body(size: 18))
            Text("Set weekly or monthly targets on distance, matches, sprints or rating.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.statLabel(size: 11))
            .foregroundStyle(Theme.Colors.textSecondary)
            .tracking(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalCard(_ goal: Goal) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(goal.metricLabel) \(goal.periodLabel)")
                        .font(Theme.Typography.body(size: 16))
                        .fontWeight(.bold)
                    Text(goal.progressDisplay)
                        .font(Theme.Typography.metric(size: 14))
                        .foregroundStyle(goal.isAchieved ? .green : Theme.Colors.textPrimary)
                }
                Spacer()
                if goal.isAchieved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 22))
                } else {
                    Button("Edit") { store.send(.editGoalTapped(goal)) }
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            if !goal.isAchieved {
                ProgressView(value: goal.progressFraction)
                    .tint(Theme.Colors.accent)
                HStack {
                    Button("Archive", role: .destructive) { store.send(.archiveGoal(goal.id)) }
                        .font(Theme.Typography.caption(size: 11))
                    Spacer()
                    Button("Delete", role: .destructive) { store.send(.deleteGoal(goal.id)) }
                        .font(Theme.Typography.caption(size: 11))
                }
            }

            if let achievedAt = goal.achievedAt {
                Text("Achieved \(achievedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.Typography.caption(size: 11))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - New Goal Form

    private var newGoalForm: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Metric", selection: $store.newMetric.sending(\.newMetricChanged)) {
                        ForEach(goalMetricOptions, id: \.id) { opt in
                            Text(opt.label).tag(opt.id)
                        }
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $store.newPeriod.sending(\.newPeriodChanged)) {
                        ForEach(goalPeriodOptions, id: \.id) { opt in
                            Text(opt.label).tag(opt.id)
                        }
                    }
                }

                Section("Target") {
                    TextField("Target value", text: $store.newTargetText.sending(\.newTargetTextChanged))
                        .keyboardType(.decimalPad)
                    if store.newMetric == "distance" {
                        Text("Distance in meters (e.g. 15000 = 15 km)")
                            .font(Theme.Typography.caption(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { store.send(.newGoalDismissed) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { store.send(.saveNewGoalTapped) }
                        .fontWeight(.bold)
                }
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }

    // MARK: - Edit Goal View

    private func editGoalView(store: StoreOf<EditGoalFeature>) -> some View {
        @Bindable var store = store
        return NavigationStack {
            Form {
                Section("Target") {
                    TextField("Target value", text: $store.targetText)
                        .keyboardType(.decimalPad)
                }
                if let error = store.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { store.send(.dismissTapped) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { store.send(.saveTapped) }
                        .fontWeight(.bold)
                    // TODO: Disable while saving
                }
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
    }
}
