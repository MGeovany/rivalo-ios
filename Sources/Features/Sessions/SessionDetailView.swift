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
            .rivalNavigationChrome(title: "Activity")
            .toolbar { toolbarContent }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .onAppear { store.send(.onAppear) }
        .alert("Save court / venue", isPresented: venuePromptBinding) {
            TextField("Venue name", text: venueDraftBinding)
            Button("Save") { store.send(.confirmVenueTapped) }
            Button("Cancel", role: .cancel) { store.send(.cancelVenueTapped) }
        } message: {
            Text("Name where you played. Shown on your activity and map.")
        }
        .confirmationDialog(
            "Delete this activity?",
            isPresented: deleteConfirmBinding,
            titleVisibility: .visible
        ) {
            Button("Delete activity", role: .destructive) { store.send(.confirmDeleteTapped) }
            Button("Cancel", role: .cancel) { store.send(.cancelDeleteTapped) }
        }
        .sheet(isPresented: shareSheetBinding) {
            if let image = shareImage {
                ActivitySheet(items: [image])
            }
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
            Button("Close") { store.send(.dismissTapped) }
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Add photos", systemImage: "photo.on.rectangle.angled")
                }
                if let session = store.session {
                    Button {
                        store.send(.editTapped)
                    } label: {
                        Label("Edit session", systemImage: "pencil")
                    }
                    Button {
                        store.send(.saveVenueTapped)
                    } label: {
                        Label("Save court", systemImage: "sportscourt")
                    }
                    Button {
                        shareImage = renderCard(session: session, meta: store.meta)
                    } label: {
                        Label("Share card", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.send(.deleteTapped)
                    } label: {
                        Label("Delete activity", systemImage: "trash")
                    }
                }
                Button("Cancel", role: .cancel) {}
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
            Text(store.errorMessage ?? "Not found")
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
            Text(session.startedAt.formatted(date: .complete, time: .shortened))
                .font(Theme.Typography.title(size: 22))

            Label(
                SessionActivityGeometry.displayLocation(session: session, meta: store.meta),
                systemImage: "mappin.and.ellipse"
            )
            .font(Theme.Typography.body(size: 15))
            .foregroundStyle(Theme.Colors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.small) {
                detailStat(session.distanceKmText, "Distance", "figure.run")
                detailStat(session.durationText, "Time", "clock.fill")
                detailStat(session.hrAvg.map { "\($0)" } ?? "—", "Avg HR", "heart.fill", unit: "bpm")
                detailStat(session.hrMax.map { "\($0)" } ?? "—", "Max HR", "bolt.heart.fill", unit: "bpm")
                detailStat("\(session.sprints)", "Sprints", "hare.fill")
                detailStat(session.intensity.map { String(format: "%.0f", $0) } ?? "—", "Intensity", "flame.fill")
            }

            if let rating = session.matchRating {
                matchRatingCard(rating)
            }

            if let fd = session.fatigueDrop {
                fatigueDropSection(fd)
            }
        }
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
                Text("Match Rating")
                    .font(Theme.Typography.statLabel(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(1)
                Text("Physical performance, not skill")
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
            Text("Fatigue Drop")
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Text("1st half vs 2nd half")
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 0) {
                halfColumn("1st", metrics: fd.firstHalf, color: Theme.Colors.accent)
                Divider()
                    .frame(width: 1)
                    .background(Theme.Colors.textSecondary.opacity(0.3))
                halfColumn("2nd", metrics: fd.secondHalf, color: Theme.Colors.positive)
            }
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

            if let change = fd.hrAvgPctChange {
                changeRow(label: "Avg HR", change: change, unit: "%")
            }
            if let change = fd.highIntensityPctChange {
                changeRow(label: "High intensity", change: change, unit: "%")
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
            Text("Avg HR")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("\(metrics.highIntensityS / 60):\(String(format: "%02d", metrics.highIntensityS % 60))")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("High int.")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(metrics.speedMaxKmh.map { String(format: "%.1f", $0) } ?? "—")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("Max speed")
                .font(Theme.Typography.caption(size: 10))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("\(metrics.sampleCount)")
                .font(Theme.Typography.metric(size: 20))
                .monospacedDigit()
            Text("Samples")
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
            Text("Photos")
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

}
