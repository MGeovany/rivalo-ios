import ComposableArchitecture
import PhotosUI
import SwiftUI

/// Create/edit form for a court: details, amenities, pricing and photos.
struct CourtEditView: View {
    @Bindable var store: StoreOf<CourtEditFeature>
    @State private var selectedPhoto: PhotosPickerItem?
    @StateObject private var compass = CompassService()
    // "Walk two points" capture: A = own goal-line center, B = rival goal-line center.
    @State private var walkA: (lat: Double, lon: Double)?
    @State private var walkB: (lat: Double, lon: Double)?

    private let types = ["5-a-side", "7-a-side", "9-a-side", "11-a-side", "Other"]
    private let surfaces = ["Natural grass", "Artificial turf", "Indoor", "Concrete", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Court") {
                    TextField("Name", text: $store.name)
                    Picker("Type", selection: $store.type) {
                        Text("None").tag("")
                        ForEach(types, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Surface", selection: $store.surface) {
                        Text("None").tag("")
                        ForEach(surfaces, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Indoor", isOn: $store.indoor)
                }

                Section("Dimensions (m)") {
                    TextField("Length", text: $store.lengthText).keyboardType(.numberPad)
                    TextField("Width", text: $store.widthText).keyboardType(.numberPad)
                }

                orientationSection

                walkMeasureSection

                Section("Notes") {
                    TextField("Anything useful about this court", text: $store.notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if store.isEditing {
                    statsSection
                }

                if store.isEditing {
                    photosSection
                } else {
                    Section {
                        Text("Save the court first to add photos.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if store.isEditing {
                    Section {
                        Button(role: .destructive) { store.send(.deleteTapped) } label: {
                            Text("Delete court")
                        }
                    }
                }

                if let error = store.errorMessage {
                    Section { Text(error).foregroundColor(.red) }
                }
            }
            .navigationTitle(store.isEditing ? "Edit court" : "New court")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.dismissTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.send(.saveTapped) }
                        .disabled(!store.canSave)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        store.send(.photoAdded(data))
                    }
                    selectedPhoto = nil
                }
            }
            .task { store.send(.onAppear) }
            .onAppear { compass.start() }
            .onDisappear { compass.stop() }
        }
    }

    /// Orientation capture: the user points the phone toward the rival goal and
    /// fixes the compass heading, so heatmaps can show absolute pitch position.
    @ViewBuilder
    private var orientationSection: some View {
        Section("Orientation") {
            if let heading = store.headingDeg {
                LabeledContent("Heading", value: String(format: "%.0f°", heading))
            } else {
                Text("If you typed the dimensions above, point the phone toward the rival goal and fix the direction. Or use “Measure by walking” below to set everything at once. Optional — enables absolute-position heatmaps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                store.headingDeg = compass.headingDeg
                // Capture the current location as the pitch center too — the
                // geo-projection needs both center and heading.
                if let lat = compass.latitude, let lon = compass.longitude {
                    store.latitude = lat
                    store.longitude = lon
                }
            } label: {
                Label(store.headingDeg == nil ? "Fix orientation" : "Re-fix orientation",
                      systemImage: "location.north.line")
            }
            .disabled(compass.headingDeg == nil)
            if store.headingDeg != nil {
                Button(role: .destructive) {
                    store.headingDeg = nil
                } label: {
                    Text("Clear orientation")
                }
            }
        }
    }

    /// "Walk two points": mark your goal-line center (A), walk to the rival
    /// goal-line center (B). Derives length, orientation and center in one go —
    /// more accurate than the compass alone.
    @ViewBuilder
    private var walkMeasureSection: some View {
        Section("Measure by walking") {
            Text("Sets length, orientation and location automatically. Stand at the center of your goal line and mark A, walk to the center of the rival goal line and mark B.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                if let lat = compass.latitude, let lon = compass.longitude {
                    walkA = (lat, lon)
                    applyWalkIfComplete()
                }
            } label: {
                Label(walkA == nil ? "Mark point A (your goal)" : "A marked ✓ — re-mark",
                      systemImage: "1.circle")
            }
            .disabled(compass.latitude == nil)
            Button {
                if let lat = compass.latitude, let lon = compass.longitude {
                    walkB = (lat, lon)
                    applyWalkIfComplete()
                }
            } label: {
                Label(walkB == nil ? "Mark point B (rival goal)" : "B marked ✓ — re-mark",
                      systemImage: "2.circle")
            }
            .disabled(compass.latitude == nil || walkA == nil)

            if walkA != nil, walkB != nil, let heading = store.headingDeg {
                LabeledContent("Captured", value: String(format: "%@ m · %.0f°", store.lengthText, heading))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
    }

    /// When both ends are marked, derive length + heading + center.
    private func applyWalkIfComplete() {
        guard let a = walkA, let b = walkB else { return }
        let length = GeoMath.distanceM(lat1: a.lat, lon1: a.lon, lat2: b.lat, lon2: b.lon)
        guard length > 0 else { return }
        store.lengthText = String(format: "%.0f", length)
        store.headingDeg = GeoMath.bearingDeg(lat1: a.lat, lon1: a.lon, lat2: b.lat, lon2: b.lon)
        let mid = GeoMath.midpoint(lat1: a.lat, lon1: a.lon, lat2: b.lat, lon2: b.lon)
        store.latitude = mid.lat
        store.longitude = mid.lon
    }

    @ViewBuilder
    private var statsSection: some View {
        if let stats = store.stats {
            Section("Stats") {
                if stats.matchCount > 0 {
                    LabeledContent("Matches played", value: "\(stats.matchCount)")
                    if let rating = stats.avgRating {
                        LabeledContent("Avg rating", value: String(format: "%.0f", rating))
                    }
                    if let dist = stats.avgDistanceM {
                        LabeledContent("Avg distance", value: String(format: "%.2f km", dist / 1000))
                    }
                    if let sprints = stats.avgSprints {
                        LabeledContent("Avg sprints", value: String(format: "%.0f", sprints))
                    }
                    if let last = stats.lastPlayedAt {
                        LabeledContent("Last played", value: last.formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    Text("No sessions logged at this court yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !stats.records.isEmpty {
                Section("Court Records") {
                    ForEach(stats.records) { record in
                        HStack {
                            Image(systemName: record.icon)
                                .foregroundStyle(record.accentColor)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.label)
                                    .font(Theme.Typography.body(size: 15))
                                Text(record.formattedValue)
                                    .font(Theme.Typography.metric(size: 14))
                                    .foregroundStyle(record.accentColor)
                            }
                            Spacer()
                            Text(record.startedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(Theme.Typography.caption(size: 10))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var photosSection: some View {
        Section("Photos") {
            if !store.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.photos) { photo in
                            ZStack(alignment: .topTrailing) {
                                if let image = UIImage(data: photo.data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 96, height: 96)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                Button {
                                    store.send(.photoDeleted(photo.id))
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                        .font(.system(size: 18))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Add photo", systemImage: "photo.on.rectangle.angled")
            }
        }
    }
}
