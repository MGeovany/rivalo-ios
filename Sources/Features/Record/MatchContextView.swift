import SwiftUI
import ComposableArchitecture

/// Post-match context form. Presented as a sheet after the session ends.
struct MatchContextView: View {
    @Bindable var store: StoreOf<MatchContextFeature>

    private let matchTypes = ["Fútbol 5", "Fútbol 7", "Fútbol 9", "Fútbol 11", "Otro"]
    private let surfaces = ["Césped natural", "Césped artificial", "Interior", "Concreto", "Otro"]
    private let positions = ["Portero", "Defensa", "Lateral", "Centrocampista", "Extremo", "Delantero"]
    private let matchTags = ["friendly", "league", "training"]
    private let outcomes = ["win", "draw", "loss"]
    private let competitions = ["friendly", "league", "tournament", "training"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de partido") {
                    Picker("Tipo", selection: $store.matchType.sending(\.setMatchType)) {
                        Text("Ninguno").tag("")
                        ForEach(matchTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Superficie") {
                    Picker("Superficie", selection: $store.surface.sending(\.setSurface)) {
                        Text("Ninguno").tag("")
                        ForEach(surfaces, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }

                Section("Posición") {
                    Picker("Posición", selection: $store.position.sending(\.setPosition)) {
                        Text("Ninguno").tag("")
                        ForEach(positions, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                }

                Section("¿Cómo te sentiste?") {
                    Picker("Sensación", selection: $store.feeling.sending(\.setFeeling)) {
                        ForEach(1...5, id: \.self) { n in
                            Text(feelingLabel(n)).tag(n)
                        }
                    }
                }

                Section("Resultado") {
                    Picker("Resultado", selection: $store.outcome.sending(\.setOutcome)) {
                        Text("Ninguno").tag("")
                        ForEach(outcomes, id: \.self) { o in
                            Text(o).tag(o)
                        }
                    }
                    }

                    if !store.outcome.isEmpty {
                        Stepper(
                            "Tus goles: \(store.teamGoals)",
                            value: $store.teamGoals.sending(\.setTeamGoals),
                            in: 0...MatchScore.maxGoals
                        )
                        Stepper(
                            "Goles rival: \(store.opponentGoals)",
                            value: $store.opponentGoals.sending(\.setOpponentGoals),
                            in: 0...MatchScore.maxGoals
                        )
                    }

                    TextField("Rival", text: $store.opponent.sending(\.setOpponent))
                }

                if !store.outcome.isEmpty {
                    Section("Tus estadísticas") {
                        Stepper("Goles: \(store.goals)", value: $store.goals.sending(\.setGoals), in: 0...20)
                        Stepper("Asistencias: \(store.assists)", value: $store.assists.sending(\.setAssists), in: 0...20)
                    }
                }

                Section("Competición") {
                    Picker("Competición", selection: $store.competition.sending(\.setCompetition)) {
                        Text("Ninguno").tag("")
                        ForEach(competitions, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    }
                }

                Section("Notas") {
                    TextField("Algo que recordar", text: $store.notes.sending(\.setNotes), axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Cancha") {
                    if store.pitchesLoading {
                        HStack {
                            ProgressView()
                            Text("Cargando canchas...")
                                .foregroundStyle(.secondary)
                        }
                    } else if store.pitches.isEmpty {
                        Text("Sin canchas guardadas. Mide una desde la pestaña Registrar.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Cancha", selection: $store.pitchId.sending(\.setPitchId)) {
                            Text("Ninguno").tag(nil as String?)
                            ForEach(store.pitches) { pitch in
                                HStack {
                                    Text(pitch.name)
                                    if let dim = pitch.dimensionsText {
                                        Text(dim).foregroundStyle(.secondary)
                                    }
                                }.tag(pitch.id as String?)
                            }
                        }
                    }
                }

                if let error = store.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Contexto del partido")
            .task { store.send(.loadPitches) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Omitir") { store.send(.dismissTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { store.send(.saveTapped) }
                        .disabled(!store.canSave)
                }
            }
        }
    }

    private func outcomeLabel(_ o: String) -> String {
        switch o {
        case "win": return "Victoria"
        case "draw": return "Empate"
        case "loss": return "Derrota"
        default: return o
        }
    }

    private func competitionLabel(_ c: String) -> String {
        switch c {
        case "friendly": return "Amistoso"
        case "league": return "Liga"
        case "tournament": return "Torneo"
        case "training": return "Entrenamiento"
        default: return c.capitalized
        }
    }

    private func feelingLabel(_ n: Int) -> String {
        switch n {
        case 1: return "1 — Pésimo"
        case 2: return "2 — Malo"
        case 3: return "3 — Regular"
        case 4: return "4 — Bueno"
        case 5: return "5 — Excelente"
        default: return "\(n)"
        }
    }
}
