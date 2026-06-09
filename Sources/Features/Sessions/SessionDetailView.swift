import ComposableArchitecture
import PhotosUI
import SwiftUI
import UIKit

struct SessionDetailView: View {
    @Bindable var store: StoreOf<SessionDetailFeature>
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                content
            }
            .rivalNavigationChrome(title: "Actividad")
            .toolbar { toolbarContent }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
        .alert("Guardar cancha / lugar", isPresented: venuePromptBinding) {
            TextField("Nombre del lugar", text: venueDraftBinding)
            Button("Guardar") { store.send(.confirmVenueTapped) }
            Button("Cancelar", role: .cancel) { store.send(.cancelVenueTapped) }
        } message: {
            Text("Nombre de dónde jugaste. Se muestra en tu actividad y mapa.")
        }
        .confirmationDialog(
            "¿Eliminar esta actividad?",
            isPresented: deleteConfirmBinding,
            titleVisibility: .visible
        ) {
            Button("Eliminar actividad", role: .destructive) { store.send(.confirmDeleteTapped) }
            Button("Cancelar", role: .cancel) { store.send(.cancelDeleteTapped) }
        }
        .sheet(isPresented: shareSheetBinding) {
            if let image = shareImage {
                ActivitySheet(items: [image])
            }
        }
        .sheet(item: $store.scope(state: \.comparison, action: \.comparison)) { comparisonStore in
            PitchComparisonView(store: comparisonStore)
        }
        .sheet(item: $store.scope(state: \.matchContext, action: \.matchContext)) { contextStore in
            MatchContextView(store: contextStore)
        }
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { shareImage != nil },
            set: { if !$0 { shareImage = nil } }
        )
    }

    private func renderCard(session: SportSession, meta: SessionMeta) -> UIImage? {
        let card = ShareCardView(session: session, meta: meta)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private var venuePromptBinding: Binding<Bool> {
        Binding(
            get: { store.showVenuePrompt },
            set: { if !$0 { store.send(.cancelVenueTapped) } }
        )
    }

    private var deleteConfirmBinding: Binding<Bool> {
        Binding(
            get: { store.showDeleteConfirm },
            set: { if !$0 { store.send(.cancelDeleteTapped) } }
        )
    }

    private var venueDraftBinding: Binding<String> {
        Binding(
            get: { store.venueDraft },
            set: { store.send(.venueDraftChanged($0)) }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cerrar") { store.send(.dismissTapped) }
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Añadir fotos", systemImage: "photo.on.rectangle.angled")
                }
                if let session = store.session {
                    Button {
                        store.send(.addResultTapped)
                    } label: {
                        Label(session.outcome == nil ? "Añadir resultado" : "Editar resultado",
                              systemImage: "flag.checkered")
                    }
                    Button {
                        store.send(.editTapped)
                    } label: {
                        Label("Editar sesión", systemImage: "pencil")
                    }
                    Button {
                        store.send(.saveVenueTapped)
                    } label: {
                        Label("Guardar cancha", systemImage: "sportscourt")
                    }
                    Button {
                        shareImage = renderCard(session: session, meta: store.meta)
                    } label: {
                        Label("Compartir tarjeta", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.send(.deleteTapped)
                    } label: {
                        Label("Eliminar actividad", systemImage: "trash")
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .medium))
            }
            .tint(Theme.Colors.accent)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.session == nil {
            LoadingView()
        } else if let session = store.session {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    mapSection(session)
                    metaSection(session)

                    if !store.photos.isEmpty {
                        photosSection
                    }

                    chartsSection(session)

                    if let message = store.errorMessage {
                        AuthInlineMessage(text: message, kind: .error)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        _ = SessionPhotoStore.append(sessionId: store.sessionId, rawImageData: data)
                        store.send(.photosChanged)
                    }
                    selectedPhoto = nil
                }
            }
        } else {
            Text(store.errorMessage ?? "No encontrado")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.negative)
                .padding()
        }
    }

    private func mapSection(_ session: SportSession) -> some View {
        PitchMapView(session: session)
    }

    private func metaSection(_ session: SportSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            if let records = session.newRecords, !records.isEmpty {
                recordBadge(records)
            }

            Text(session.startedAt.formatted(date: .complete, time: .shortened))
                .font(Theme.Typography.title(size: 22))

            Label(
                SessionActivityGeometry.displayLocation(session: session, meta: store.meta),
                systemImage: "mappin.and.ellipse"
            )
            .font(Theme.Typography.body(size: 15))
            .foregroundStyle(Theme.Colors.textSecondary)

            contextChips(session)

            if session.outcome != nil || session.opponent != nil {
                resultSection(session)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.small) {
                detailStat(session.distanceKmText, "Distancia", "figure.run")
                detailStat(session.durationText, "Tiempo", "clock.fill")
                detailStat(session.hrAvg.map { "\($0)" } ?? "—", "FC media", "heart.fill", unit: "bpm")
                detailStat(session.hrMax.map { "\($0)" } ?? "—", "FC máx", "bolt.heart.fill", unit: "bpm")
                detailStat("\(session.sprints)", "Sprints", "hare.fill")
                detailStat(session.intensity.map { String(format: "%.0f", $0) } ?? "—", "Intensidad", "flame.fill")
            }

            if let insights = session.matchInsights, !insights.isEmpty {
                matchInsightsSection(insights)
            }

            if let rating = session.matchRating {
                matchRatingCard(rating)
            }

            if let averages = store.averages {
                vsAverageSection(session, averages: averages)
            }

            if let fd = session.fatigueDrop {
                fatigueDropSection(fd)
            }

            if session.pitchId != nil {
                comparePitchButton
            }
        }
    }

    @ViewBuilder
    private func contextChips(_ session: SportSession) -> some View {
        let chips: [(String, String)] = [
            session.position.map { ("figure.soccer", $0) },
            session.matchType.map { ("sportscourt", $0) },
            session.surface.map { ("leaf.fill", $0) },
        ].compactMap { $0 }

        if !chips.isEmpty {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(chips, id: \.1) { icon, text in
                    Label(text, systemImage: icon)
                        .font(Theme.Typography.caption(size: 12))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.surface)
                        .clipShape(Capsule())
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func resultSection(_ session: SportSession) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            if let outcome = session.outcome {
                Text(Self.outcomeLetter(outcome))
                    .font(Theme.Typography.metric(size: 22))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Self.outcomeColor(outcome))
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let score = session.score {
                        Text(score).font(Theme.Typography.title(size: 18))
                    }
                    if let opponent = session.opponent {
                        Text("vs \(opponent)")
                            .font(Theme.Typography.body(size: 15))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                HStack(spacing: 8) {
                    if let comp = session.competition {
                        Text(comp.capitalized)
                            .font(Theme.Typography.caption(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    if let g = session.goals, let a = session.assists {
                        Text("\(g) G · \(a) A")
                            .font(Theme.Typography.caption(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private static func outcomeLetter(_ o: String) -> String {
        switch o {
        case "win": return "W"
        case "draw": return "D"
        case "loss": return "L"
        default: return "?"
        }
    }

    private static func outcomeColor(_ o: String) -> Color {
        switch o {
        case "win": return Theme.Colors.positive
        case "draw": return Theme.Colors.accent
        case "loss": return Theme.Colors.negative
        default: return Theme.Colors.surface
        }
    }

    private func recordBadge(_ records: [String]) -> some View {
        let names = records.map(Self.recordLabel).joined(separator: " · ")
        return HStack(spacing: Theme.Spacing.small) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14, weight: .bold))
            Text("Nuevo récord personal: \(names)")
                .font(Theme.Typography.body(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.black)
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    @ViewBuilder
    private func vsAverageSection(_ session: SportSession, averages: StatsAverages) -> some View {
        let rows = Self.comparisonRows(session: session, averages: averages)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("VS TU MEDIA")
                    .font(Theme.Typography.statLabel(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(1)

                ForEach(rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(Theme.Typography.body(size: 14))
                        Spacer()
                        Image(systemName: row.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(String(format: "%+.0f%%", row.delta))
                            .font(Theme.Typography.metric(size: 15))
                            .monospacedDigit()
                    }
                    .foregroundStyle(row.delta >= 0 ? Theme.Colors.positive : Theme.Colors.textSecondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
            }
        }
    }

    private static func recordLabel(_ metric: String) -> String {
        switch metric {
        case "distance_m": return "Distancia"
        case "duration_s": return "Tiempo"
        case "speed_max_kmh": return "Velocidad máxima"
        case "sprints": return "Sprints"
        case "intensity": return "Intensidad"
        case "match_rating": return "Valoración"
        case "hr_max": return "FC máx"
        case "calories_kcal": return "Calorías"
        default: return metric
        }
    }

    private struct ComparisonRow {
        let label: String
        let delta: Double
    }

    private static func comparisonRows(session: SportSession, averages: StatsAverages) -> [ComparisonRow] {
        var rows: [ComparisonRow] = []
        func pct(_ value: Double, _ avg: Double?) -> Double? {
            guard let avg, avg > 0 else { return nil }
            return (value - avg) / avg * 100
        }
        if let d = pct(session.distanceM, averages.distancePerMatch) {
            rows.append(ComparisonRow(label: "Distancia", delta: d))
        }
        if let d = pct(Double(session.durationS), averages.durationPerMatch) {
            rows.append(ComparisonRow(label: "Tiempo", delta: d))
        }
        if let d = pct(Double(session.sprints), averages.sprintsPerMatch) {
            rows.append(ComparisonRow(label: "Sprints", delta: d))
        }
        if let intensity = session.intensity, let d = pct(intensity, averages.intensity) {
            rows.append(ComparisonRow(label: "Intensidad", delta: d))
        }
        if let rating = session.matchRating, let d = pct(rating, averages.matchRating) {
            rows.append(ComparisonRow(label: "Valoración", delta: d))
        }
        return rows
    }

    private var comparePitchButton: some View {
        Button {
            store.send(.comparePitchTapped)
        } label: {
            Label("Comparar en esta cancha", systemImage: "chart.bar.xaxis")
                .font(Theme.Typography.body(size: 15))
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.medium)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .tint(Theme.Colors.accent)
    }

    private func matchRatingCard(_ rating: Double) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.surface, lineWidth: 4)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: CGFloat(rating / 100))
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)
                Text(String(format: "%.0f", rating))
                    .font(Theme.Typography.metric(size: 22))
                    .foregroundStyle(Theme.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Valoración")
                    .font(Theme.Typography.statLabel(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(1)
                Text("Rendimiento físico, no habilidad")
                    .font(Theme.Typography.caption(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func fatigueDropSection(_ fd: FatigueDrop) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Caída de rendimiento")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Text("1er tiempo vs 2do tiempo")
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 0) {
                halfColumn("1er", metrics: fd.firstHalf, color: Theme.Colors.accent)
                Divider()
                    .frame(width: 1)
                    .background(Theme.Colors.textSecondary.opacity(0.3))
                halfColumn("2do", metrics: fd.secondHalf, color: Theme.Colors.positive)
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

            if let change = fd.hrAvgPctChange {
                changeRow(label: "FC media", change: change, unit: "%")
            }
            if let change = fd.highIntensityPctChange {
                changeRow(label: "Intensidad alta", change: change, unit: "%")
            }
        }
    }

    private func halfColumn(_ title: String, metrics: HalfMetrics, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            Text(title)
                .font(Theme.Typography.statLabel(size: 12))
                .foregroundStyle(color)
                .tracking(1)
                .padding(.top, 4)

            Text(metrics.hrAvg.map { String(format: "%.0f", $0) } ?? "—")
                .font(Theme.Typography.metric(size: 22))
                .monospacedDigit()
            Text("FC media")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("\(metrics.highIntensityS / 60):\(String(format: "%02d", metrics.highIntensityS % 60))")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("Int. alta")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(metrics.speedMaxKmh.map { String(format: "%.1f", $0) } ?? "—")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("Vel. máxima")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("\(metrics.sampleCount)")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("Muestras")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.medium)
    }

    private func changeRow(label: String, change: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body(size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(String(format: "%+.1f \(unit)", change))
                .font(Theme.Typography.metric(size: 16))
                .foregroundStyle(change >= 0 ? Theme.Colors.positive : Theme.Colors.negative)
                .monospacedDigit()
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Fotos")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(Array(store.photos.enumerated()), id: \.offset) { _, data in
                        if let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chartsSection(_ session: SportSession) -> some View {
        let samples = session.samples ?? []
        let hrSamples = samples.filter { $0.hr != nil }
        let speedSamples = samples.filter { $0.speedKmh != nil }

        if hrSamples.count >= 2 {
            SessionDetailCharts.heartRateCard(hrSamples)
        }
        if speedSamples.count >= 2 {
            SessionDetailCharts.speedCard(speedSamples)
        }
        if samples.count >= 2 {
            SessionDetailCharts.distanceCard(samples, totalDistanceM: session.distanceM)
        }
        if let intensity = session.intensity {
            SessionDetailCharts.intensityCard(intensity: intensity)
        }
    }

    private func detailStat(_ value: String, _ label: String, _ icon: String, unit: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.accent)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.metric(size: 26))
                    .monospacedDigit()
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.statLabel(size: 11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            Text(label)
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    @ViewBuilder
    private func matchInsightsSection(_ insights: [MatchInsight]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("ESTADÍSTICAS DEL PARTIDO")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            ForEach(insights) { insight in
                HStack(spacing: Theme.Spacing.small) {
                    Image(systemName: insightIcon(insight.kind))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(Theme.Typography.body(size: 14))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(insight.message)
                            .font(Theme.Typography.caption(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
        }
    }

    private func insightIcon(_ kind: String) -> String {
        switch kind {
        case "distance_burst": "figure.run"
        case "sprint_peak": "hare.fill"
        case "duration_record": "clock.fill"
        case "rating_boost": "star.fill"
        case "intensity_peak": "flame.fill"
        default: "sparkles"
        }
    }
}
