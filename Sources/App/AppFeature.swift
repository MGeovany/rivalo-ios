import ComposableArchitecture

/// Root reducer for the app. In Phase 1 it only hosts the server status check;
/// authentication, profile, history and other features compose in here later.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var serverStatus = ServerStatusFeature.State()
    }

    enum Action {
        case serverStatus(ServerStatusFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.serverStatus, action: \.serverStatus) {
            ServerStatusFeature()
        }
    }
}
