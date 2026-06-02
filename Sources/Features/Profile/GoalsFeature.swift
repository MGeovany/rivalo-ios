import ComposableArchitecture
import Foundation

@Reducer
struct GoalsFeature {
    @ObservableState
    struct State: Equatable {
        var accessToken: String
        var goals: [Goal] = []
        var isLoading = false
        var errorMessage: String?

        // New goal form
        var showNewForm = false
        var newMetric = "distance"
        var newPeriod = "week"
        var newTargetText = ""
        @Presents var editGoal: EditGoalFeature.State?

        var achieved: [Goal] { goals.filter(\.isAchieved) }
        var active: [Goal] { goals.filter { !$0.isAchieved } }
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<[Goal], APIError>)
        case dismissTapped
        case newGoalTapped
        case newGoalDismissed
        case newMetricChanged(String)
        case newPeriodChanged(String)
        case newTargetTextChanged(String)
        case saveNewGoalTapped
        case saveNewGoalResponse(Result<Goal, APIError>)
        case deleteGoal(String)
        case deleteGoalResponse(Result<String, APIError>)
        case archiveGoal(String)
        case archiveGoalResponse(Result<Goal, APIError>)
        case editGoalTapped(Goal)
        case editGoal(PresentationAction<EditGoalFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case dismissed
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = state.goals.isEmpty
                let token = state.accessToken
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.fetchGoals(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .loadResponse(.success(goals)):
                state.isLoading = false
                state.goals = goals
                return .none

            case .loadResponse(.failure):
                state.isLoading = false
                state.errorMessage = "Could not load your goals."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .newGoalTapped:
                state.showNewForm = true
                state.newMetric = "distance"
                state.newPeriod = "week"
                state.newTargetText = ""
                return .none

            case .newGoalDismissed:
                state.showNewForm = false
                return .none

            case let .newMetricChanged(m):
                state.newMetric = m
                return .none

            case let .newPeriodChanged(p):
                state.newPeriod = p
                return .none

            case let .newTargetTextChanged(t):
                state.newTargetText = t
                return .none

            case .saveNewGoalTapped:
                guard let target = Double(state.newTargetText), target > 0 else {
                    state.errorMessage = "Enter a valid target > 0."
                    return .none
                }
                state.errorMessage = nil
                let token = state.accessToken
                let new = NewGoal(metric: state.newMetric, period: state.newPeriod, target: target)
                return .run { send in
                    await send(.saveNewGoalResponse(Result { try await apiClient.createGoal(token, new) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .saveNewGoalResponse(.success(goal)):
                state.showNewForm = false
                state.goals.insert(goal, at: 0)
                return .none

            case .saveNewGoalResponse(.failure):
                state.errorMessage = "Could not create goal."
                return .none

            case let .deleteGoal(id):
                let token = state.accessToken
                return .run { send in
                    await send(.deleteGoalResponse(Result { try await apiClient.deleteGoal(token, id); return id }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .deleteGoalResponse(.success(id)):
                state.goals.removeAll { $0.id == id }
                return .none

            case .deleteGoalResponse(.failure):
                state.errorMessage = "Could not delete goal."
                return .none

            case let .archiveGoal(id):
                let token = state.accessToken
                let update = GoalUpdate(metric: nil, period: nil, target: nil, archived: true)
                return .run { send in
                    await send(.archiveGoalResponse(Result { try await apiClient.updateGoal(token, id, update) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case let .archiveGoalResponse(.success(goal)):
                state.goals.removeAll { $0.id == goal.id }
                return .none

            case .archiveGoalResponse(.failure):
                state.errorMessage = "Could not archive goal."
                return .none

            case let .editGoalTapped(goal):
                state.editGoal = EditGoalFeature.State(
                    accessToken: state.accessToken,
                    goal: goal
                )
                return .none

            case .editGoal(.presented(.delegate(.dismissed))):
                let token = state.accessToken
                state.editGoal = nil
                return .run { send in
                    await send(.loadResponse(Result { try await apiClient.fetchGoals(token) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .editGoal:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$editGoal, action: \.editGoal) {
            EditGoalFeature()
        }
    }
}

// MARK: - Edit Goal Feature

@Reducer
struct EditGoalFeature {
    @ObservableState
    struct State: Equatable {
        let accessToken: String
        let goal: Goal
        var targetText: String
        var metric: String
        var period: String
        var isSaving = false
        var errorMessage: String?

        init(accessToken: String, goal: Goal) {
            self.accessToken = accessToken
            self.goal = goal
            targetText = "\(Int(goal.target))"
            metric = goal.metric
            period = goal.period
        }
    }

    enum Action: Equatable {
        case saveTapped
        case saveResponse(Result<Goal, APIError>)
        case dismissTapped
        case delegate(Delegate)
        enum Delegate: Equatable {
            case dismissed
        }
    }

    @Dependency(\.apiClient) var apiClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .saveTapped:
                guard let target = Double(state.targetText), target > 0 else {
                    state.errorMessage = "Enter a valid target > 0."
                    return .none
                }
                state.isSaving = true
                let token = state.accessToken
                let id = state.goal.id
                let update = GoalUpdate(metric: state.metric, period: state.period, target: target, archived: nil)
                return .run { send in
                    await send(.saveResponse(Result { try await apiClient.updateGoal(token, id, update) }
                        .mapError { $0 as? APIError ?? .invalidResponse }))
                }

            case .saveResponse(.success):
                state.isSaving = false
                return .send(.delegate(.dismissed))

            case .saveResponse(.failure):
                state.isSaving = false
                state.errorMessage = "Could not save goal."
                return .none

            case .dismissTapped:
                return .send(.delegate(.dismissed))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Metric options

let goalMetricOptions = [
    (id: "distance", label: "Distance"),
    (id: "matches", label: "Matches"),
    (id: "sprints", label: "Sprints"),
    (id: "rating", label: "Rating"),
]

let goalPeriodOptions = [
    (id: "week", label: "Weekly"),
    (id: "month", label: "Monthly"),
]
