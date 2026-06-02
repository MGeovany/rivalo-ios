import ComposableArchitecture
import PhotosUI
import SwiftUI

/// Create/edit form for a court: details, amenities, pricing and photos.
struct CourtEditView: View {
    @Bindable var store: StoreOf<CourtEditFeature>
    @State private var selectedPhoto: PhotosPickerItem?

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
        }
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
                                    .font(Theme.Typography.statValue(size: 14))
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
