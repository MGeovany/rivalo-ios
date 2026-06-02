import SwiftUI
import ComposableArchitecture

/// Post-match context form. Presented as a sheet after the session ends.
struct MatchContextView: View {
    @Bindable var store: StoreOf<MatchContextFeature>

    private let matchTypes = ["5-a-side", "7-a-side", "9-a-side", "11-a-side", "Other"]
    private let surfaces = ["Natural grass", "Artificial turf", "Indoor", "Concrete", "Other"]
    private let positions = ["Goalkeeper", "Defender", "Full-back", "Midfielder", "Winger", "Forward"]
    private let matchTags = ["friendly", "league", "training"]
    private let outcomes = ["win", "draw", "loss"]
    private let competitions = ["friendly", "league", "tournament", "training"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Match type") {
                    Picker("Type", selection: $store.matchType.sending(\.setMatchType)) {
                        Text("None").tag("")
                        ForEach(matchTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Surface") {
                    Picker("Surface", selection: $store.surface.sending(\.setSurface)) {
                        Text("None").tag("")
                        ForEach(surfaces, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }

                Section("Position") {
                    Picker("Position", selection: $store.position.sending(\.setPosition)) {
                        Text("None").tag("")
                        ForEach(positions, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                }

                Section("How did it feel?") {
                    Picker("Feeling", selection: $store.feeling.sending(\.setFeeling)) {
                        ForEach(1...5, id: \.self) { n in
                            Text(feelingLabel(n)).tag(n)
                        }
                    }
                }

                Section("Result") {
                    Picker("Outcome", selection: $store.outcome.sending(\.setOutcome)) {
                        Text("None").tag("")
                        ForEach(outcomes, id: \.self) { o in
                            Text(outcomeLabel(o)).tag(o)
                        }
                    }

                    if !store.outcome.isEmpty {
                        Stepper(
                            "Your goals: \(store.teamGoals)",
                            value: $store.teamGoals.sending(\.setTeamGoals),
                            in: 0...MatchScore.maxGoals
                        )
                        Stepper(
                            "Opponent goals: \(store.opponentGoals)",
                            value: $store.opponentGoals.sending(\.setOpponentGoals),
                            in: 0...MatchScore.maxGoals
                        )
                    }

                    TextField("Opponent", text: $store.opponent.sending(\.setOpponent))
                }

                if !store.outcome.isEmpty {
                    Section("Your stats") {
                        Stepper("Goals: \(store.goals)", value: $store.goals.sending(\.setGoals), in: 0...20)
                        Stepper("Assists: \(store.assists)", value: $store.assists.sending(\.setAssists), in: 0...20)
                    }
                }

                Section("Competition") {
                    Picker("Competition", selection: $store.competition.sending(\.setCompetition)) {
                        Text("None").tag("")
                        ForEach(competitions, id: \.self) { c in
                            Text(competitionLabel(c)).tag(c)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything to remember", text: $store.notes.sending(\.setNotes), axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Pitch") {
                    if store.pitchesLoading {
                        HStack {
                            ProgressView()
                            Text("Loading pitches...")
                                .foregroundStyle(.secondary)
                        }
                    } else if store.pitches.isEmpty {
                        Text("No saved pitches. Measure one from the Record tab.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Pitch", selection: $store.pitchId.sending(\.setPitchId)) {
                            Text("None").tag(nil as String?)
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
            .navigationTitle("Match Context")
            .task { store.send(.loadPitches) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { store.send(.dismissTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.send(.saveTapped) }
                        .disabled(!store.canSave)
                }
            }
        }
    }

    private func outcomeLabel(_ o: String) -> String {
        switch o {
        case "win": return "Win"
        case "draw": return "Draw"
        case "loss": return "Loss"
        default: return o
        }
    }

    private func competitionLabel(_ c: String) -> String {
        switch c {
        case "friendly": return "Friendly"
        case "league": return "League"
        case "tournament": return "Tournament"
        case "training": return "Entrenamiento"
        default: return c.capitalized
        }
    }

    private func feelingLabel(_ n: Int) -> String {
        switch n {
        case 1: return "1 — Terrible"
        case 2: return "2 — Bad"
        case 3: return "3 — Okay"
        case 4: return "4 — Good"
        case 5: return "5 — Great"
        default: return "\(n)"
        }
    }
}
