import ComposableArchitecture
import SwiftUI

/// Displays backend connectivity and lets the user re-check it.
struct ServerStatusView: View {
    @Bindable var store: StoreOf<ServerStatusFeature>

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.large) {
                BrandLogo(style: .wordmark, height: 28)
                    .frame(maxWidth: .infinity)

                statusCard

                Button {
                    store.send(.checkTapped)
                } label: {
                    Text("Verificar de nuevo")
                        .font(Theme.Typography.button())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.accent)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
            }
            .padding(Theme.Spacing.large)
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
    }

    private var statusCard: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text("Servidor")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.Colors.textSecondary)

            switch store.connection {
            case .idle, .checking:
                LoadingView(style: .compact)

            case let .online(database):
                Text("En línea")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.positive)
                Text("database: \(database)")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)

            case let .offline(message):
                Text("Fuera de línea")
                    .font(Theme.Typography.title())
                    .foregroundStyle(Theme.Colors.negative)
                Text(message)
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    ServerStatusView(
        store: Store(initialState: ServerStatusFeature.State()) {
            ServerStatusFeature()
        }
    )
}
