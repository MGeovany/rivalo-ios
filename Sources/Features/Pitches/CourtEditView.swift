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
                Section("Cancha") {
                    TextField("Nombre", text: $store.name)
                    Picker("Tipo", selection: $store.type) {
                        Text("Ninguno").tag("")
                        ForEach(types, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Superficie", selection: $store.surface) {
                        Text("Ninguno").tag("")
                        ForEach(surfaces, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Interior", isOn: $store.indoor)
                }

                Section("Dimensiones (m)") {
                    TextField("Largo", text: $store.lengthText).keyboardType(.numberPad)
                    TextField("Ancho", text: $store.widthText).keyboardType(.numberPad)
                }

                orientationSection

                walkMeasureSection

                Section("Notas") {
                    TextField("Cualquier cosa útil sobre esta cancha", text: $store.notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if store.isEditing {
                    statsSection
                }

                if store.isEditing {
                    photosSection
                } else {
                    Section {
                        Text("Guarda la cancha primero para añadir fotos.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if store.isEditing {
                    Section {
                        Button(role: .destructive) { store.send(.deleteTapped) } label: {
                            Text("Eliminar cancha")
                        }
                    }
                }

                if let error = store.errorMessage {
                    Section { Text(error).foregroundColor(.red) }
                }
            }
            .navigationTitle(store.isEditing ? "Editar cancha" : "Nueva cancha")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { store.send(.dismissTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { store.send(.saveTapped) }
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
        Section("Orientación") {
            if let heading = store.headingDeg {
                LabeledContent("Dirección", value: String(format: "%.0f°", heading))
            } else {
                Text("Si has escrito las dimensiones arriba, apunta el teléfono hacia la portería rival y fija la dirección. O usa \"Medir caminando\" más abajo para configurarlo todo de una vez. Opcional — permite mapas de calor con posición absoluta.")
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
                Label(store.headingDeg == nil ? "Fijar orientación" : "Refijar orientación",
                      systemImage: "location.north.line")
            }
            .disabled(compass.headingDeg == nil)
            if store.headingDeg != nil {
                Button(role: .destructive) {
                    store.headingDeg = nil
                } label: {
                    Text("Limpiar orientación")
                }
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
                Label(store.headingDeg == nil ? "Fijar orientación" : "Refijar orientación",
                      systemImage: "location.north.line")
            }
            .disabled(compass.headingDeg == nil)
            if store.headingDeg != nil {
                Button(role: .destructive) {
                    store.headingDeg = nil
                } label: {
                    Text("Limpiar orientación")
                }
            }
        }
    }

    /// "Walk two points": mark your goal-line center (A), walk to the rival
    /// goal-line center (B). Derives length, orientation and center in one go —
    /// more accurate than the compass alone.
    @ViewBuilder
    private var walkMeasureSection: some View {
        Section("Medir caminando") {
            Text("Configura el largo, la orientación y la ubicación automáticamente. Ponte en el centro de tu línea de gol y marca A, camina hasta el centro de la línea de gol rival y marca B.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button {
                if let lat = compass.latitude, let lon = compass.longitude {
                    walkA = (lat, lon)
                    applyWalkIfComplete()
                }
            } label: {
                Label(walkA == nil ? "Marca punto A (tu portería)" : "A marcado ✓ — remarcar",
                      systemImage: "1.circle")
            }
            .disabled(compass.latitude == nil)
            Button {
                if let lat = compass.latitude, let lon = compass.longitude {
                    walkB = (lat, lon)
                    applyWalkIfComplete()
                }
            } label: {
                Label(walkB == nil ? "Marca punto B (portería rival)" : "B marcado ✓ — remarcar",
                      systemImage: "2.circle")
            }
            .disabled(compass.latitude == nil || walkA == nil)

            if walkA != nil, walkB != nil, let heading = store.headingDeg {
                LabeledContent("Capturado", value: String(format: "%@ m · %.0f°", store.lengthText, heading))
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
            Section("Estadísticas") {
                if stats.matchCount > 0 {
                    LabeledContent("Partidos jugados", value: "\(stats.matchCount)")
                    if let rating = stats.avgRating {
                        LabeledContent("Valoración media", value: String(format: "%.0f", rating))
                    }
                    if let dist = stats.avgDistanceM {
                        LabeledContent("Distancia media", value: String(format: "%.2f km", dist / 1000))
                    }
                    if let sprints = stats.avgSprints {
                        LabeledContent("Sprints medios", value: String(format: "%.0f", sprints))
                    }
                    if let last = stats.lastPlayedAt {
                        LabeledContent("Último partido", value: last.formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    Text("Aún no hay sesiones registradas en esta cancha.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !stats.records.isEmpty {
                Section("Récords de la cancha") {
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
        Section("Fotos") {
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
                Label("Añadir foto", systemImage: "photo.on.rectangle.angled")
            }
        }
    }
}
