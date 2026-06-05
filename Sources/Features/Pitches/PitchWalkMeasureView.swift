import CoreLocation
import SwiftUI

struct PitchWalkMeasureView: View {
    let accessToken: String
    var onBack: () -> Void

    @State private var gps = PhoneGPSObserver()
    @State private var step: MeasureStep = .length
    @State private var courtName = ""
    @State private var isSaving = false
    @State private var saveError: String?

    @Environment(\.openURL) private var openURL

    enum MeasureStep: Equatable {
        case length
        case width(length: Double)
        case confirm(length: Double, width: Double)
        case saved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Label("GPS measurement", systemImage: "location.fill")
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Theme.Colors.accent)

                switch step {
                case .length:
                    segmentCard(
                        title: "Step 1 of 2 — Length",
                        hint: "Jog from one goal line to the other with your phone.",
                        isFirstSegment: true
                    ) { meters in
                        gps.reset()
                        step = .width(length: meters)
                    }

                case .width(let length):
                    segmentCard(
                        title: "Step 2 of 2 — Width",
                        hint: "Jog from one touchline to the other.",
                        isFirstSegment: false
                    ) { meters in
                        gps.reset()
                        step = .confirm(length: length, width: meters)
                    }

                    Button {
                        gps.reset()
                        step = .length
                    } label: {
                        Label("Redo length", systemImage: "arrow.uturn.left")
                            .font(Theme.Typography.body(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                case .confirm(let length, let width):
                    confirmCard(length: length, width: width)

                case .saved:
                    savedCard
                }

                Button("Back to methods", action: onBack)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
        .onAppear {
            if gps.authStatus == .notDetermined {
                gps.requestPermission()
            }
        }
    }

    // MARK: - Segment card

    private func segmentCard(
        title: String,
        hint: String,
        isFirstSegment: Bool,
        onCaptured: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(Theme.Typography.title(size: 18))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(hint)
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)

            distanceDisplay

            if gps.authStatus == .denied || gps.authStatus == .restricted {
                deniedView
            } else {
                gpsControls(isFirstSegment: isFirstSegment, onCaptured: onCaptured)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var distanceDisplay: some View {
        let distance: Double = {
            switch gps.segmentState {
            case .measuring(let d): return d
            case .captured(let m): return m
            default: return 0
            }
        }()
        return Text(String(format: "%.1f m", distance))
            .font(.system(size: 52, weight: .bold, design: .monospaced))
            .foregroundStyle(distance > 0 ? Theme.Colors.accent : Theme.Colors.textSecondary.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Theme.Spacing.small)
    }

    @ViewBuilder
    private func gpsControls(isFirstSegment: Bool, onCaptured: @escaping (Double) -> Void) -> some View {
        switch gps.segmentState {
        case .idle:
            primaryButton(label: "Start") {
                gps.start(isFirstSegment: isFirstSegment)
            }

        case .waitingForFix:
            HStack(spacing: Theme.Spacing.small) {
                ProgressView().tint(Theme.Colors.accent)
                Text("Waiting for GPS…")
                    .font(Theme.Typography.body(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            stopButton

        case .measuring:
            stopButton

        case .captured(let meters):
            if meters >= 5 {
                primaryButton(label: String(format: "Use %.1f m →", meters)) {
                    onCaptured(meters)
                }
            } else {
                Text("Too short — jog a longer distance and try again.")
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Button("Redo") { gps.reset() }
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
        }
    }

    private func primaryButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var stopButton: some View {
        Button { gps.stop() } label: {
            Text("Stop")
                .font(Theme.Typography.button(size: 16))
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.Colors.accent.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var deniedView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label("Location access needed", systemImage: "location.slash.fill")
                .font(Theme.Typography.title(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Allow location access in Settings so Rivalo can measure the pitch with GPS.")
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
            Button("Open Settings") {
                if let url = URL(string: "app-settings:") { openURL(url) }
            }
            .font(Theme.Typography.body(size: 15))
            .foregroundStyle(Theme.Colors.accent)
        }
    }

    // MARK: - Confirm card

    private func confirmCard(length: Double, width: Double) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Measured dimensions")
                .font(Theme.Typography.title(size: 18))
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.medium) {
                dimensionTile(label: "Length", meters: length)
                dimensionTile(label: "Width", meters: width)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("COURT NAME (OPTIONAL)")
                    .font(Theme.Typography.statLabel(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
                TextField("e.g. Pitch 1", text: $courtName)
                    .font(Theme.Typography.body(size: 16))
                    .padding(Theme.Spacing.medium)
                    .background(Theme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let err = saveError {
                Text(err)
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(.red)
            }

            Button(isSaving ? "Saving…" : "Save court") {
                Task { await save(length: length, width: width) }
            }
            .font(Theme.Typography.button(size: 16))
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(!isSaving ? Theme.Colors.accent : Theme.Colors.surface)
            .clipShape(Capsule())
            .disabled(isSaving)
            .buttonStyle(.plain)

            HStack(spacing: Theme.Spacing.large) {
                Button("Redo width") { step = .width(length: length) }
                    .font(Theme.Typography.body(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Button("Redo length") { step = .length }
                    .font(Theme.Typography.body(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dimensionTile(label: String, meters: Double) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(Theme.Typography.statLabel(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(String(format: "%.1f m", meters))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.medium)
        .background(Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Saved card

    private var savedCard: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.Colors.accent)
            Text("Court saved.")
                .font(Theme.Typography.title(size: 20))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("It will appear on your watch when you're nearby.")
                .font(Theme.Typography.body(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Save

    private func save(length: Double, width: Double) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        saveError = nil

        let name = courtName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await PitchesSync.create(
                accessToken: accessToken,
                apiClient: APIClient.liveValue,
                pitch: NewPitch(
                    name: name.isEmpty ? CourtDefaultName.make() : name,
                    latitude: gps.pitchLocation?.coordinate.latitude,
                    longitude: gps.pitchLocation?.coordinate.longitude,
                    lengthM: length,
                    widthM: width,
                    measurementMethod: PitchMeasurementMethod.walk.rawValue
                )
            )
            step = .saved
        } catch {
            saveError = "Could not save. Check your connection and try again."
        }
    }
}
