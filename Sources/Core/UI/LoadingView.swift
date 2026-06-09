import SwiftUI

enum LoadingMessages {
    static let all = [
        "Atando botas…",
        "Calentando…",
        "Revisando la cancha…",
        "Buscando tus botas…",
        "Sacando el balón…",
        "Leyendo la hoja de partido…",
        "Casi al saque inicial…",
        "Discutiendo sobre el fuera de juego…",
        "Untando al árbitro con naranjas…",
        "Fingiendo que ese pase fue intencional…",
        "Calculando excusas por llegar tarde…",
        "Inflando la hoja de estadísticas (solo un poco)…",
        "Escondiendo la entrada extra…",
        "Convenciendo al capitán de que estás en forma…",
        "Echándote un ojo en YouTube…",
        "Esquivando el calentamiento del grupo…",
        "Echándole la culpa a las botas (otra vez)…",
        "Calculando la pausa para agua perfectamente…",
        "Verificando si realmente está lloviendo…",
        "Saltándose el trote previo al partido…",
        "Puliendo la fantasía de la bota de oro…",
        "Llegando tarde pero sprintando ahora…",
        "Descifrando las señales del entrenador…",
        "Buscando dónde estacionaste la semana pasada…",
        "Repitiendo ese único buen control…",
        "Convirtiendo esfuerzo en derechos de fanfarronear…",
        "Verificando tu velocidad máxima…",
        "Descargando chismes de la banda…",
        "Midiendo el bronceado de la línea de banda…",
        "Negociando estacionamiento en la cancha…",
        "Sincronizando tu aura de liga dominical…",
        "Pidiéndole al portero un arco a cero…",
        "Contando pasos hasta el punto penal…",
        "Revisando metraje que nadie pidió…",
        "Estirando un isquiotibial a la vez…",
    ]
}

/// Rotating status line shown while waiting on the backend.
struct CyclingLoadingMessage: View {
    var interval: Duration = .seconds(2)

    @State private var messageIndex = Int.random(in: 0..<LoadingMessages.all.count)

    var body: some View {
        Text(LoadingMessages.all[messageIndex])
            .font(Theme.Typography.caption(size: 14))
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(minHeight: 20)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.35), value: messageIndex)
            .task { await cycleMessages() }
    }

    private func cycleMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            messageIndex = (messageIndex + 1) % LoadingMessages.all.count
        }
    }
}

/// Spinner plus rotating message for network fetches.
struct LoadingView: View {
    enum Style {
        /// Fills available space — use in full-screen or list placeholders.
        case standard
        /// Tight stack for cards, splash, or below buttons.
        case compact
    }

    var style: Style = .standard
    var showsSpinner: Bool = true

    var body: some View {
        Group {
            switch style {
            case .standard:
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .compact:
                content
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if showsSpinner {
                ProgressView()
                    .tint(Theme.Colors.accent)
                    .scaleEffect(0.95)
            }
            CyclingLoadingMessage()
        }
    }
}

#Preview("Loading") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        LoadingView()
    }
}
