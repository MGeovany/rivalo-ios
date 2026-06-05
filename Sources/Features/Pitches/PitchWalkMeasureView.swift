import ARKit
import SwiftUI

struct PitchWalkMeasureView: View {
    let accessToken: String
    var onBack: () -> Void

    @State private var ar = PhoneARObserver()
    @State private var step: MeasureStep = .length
    @State private var courtName = ""
    @State private var isSaving = false
    @State private var saveError: String?

    enum MeasureStep: Equatable {
        case length
        case width(length: Double)
        case confirm(length: Double, width: Double)
        case saved
    }

    var body: some View {
        switch step {
        case .length, .width:
            cameraScreen
        case .confirm(let length, let width):
            confirmScreen(length: length, width: width)
        case .saved:
            savedScreen
        }
    }

    // MARK: - Camera screen

    private var cameraScreen: some View {
        ZStack(alignment: .bottom) {
            ARCameraPreview(session: ar.session)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                stepBadge
                    .padding(.top, 52)
                Spacer()
                hud
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }

    private var stepBadge: some View {
        let title: String
        let hint: String
        switch step {
        case .length:
            title = "Step 1 of 2 — Length"
            hint = "Walk from one goal line to the other"
        default:
            title = "Step 2 of 2 — Width"
            hint = "Walk from one touchline to the other"
        }
        return VStack(spacing: 4) {
            Text(title)
                .font(Theme.Typography.title(size: 15))
                .foregroundStyle(.white)
            Text(hint)
                .font(Theme.Typography.body(size: 13))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var hud: some View {
        VStack(spacing: Theme.Spacing.medium) {
            trackingStatusRow
            distanceLabel
            hudControls
        }
        .padding(Theme.Spacing.xl)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
        .padding(.horizontal, Theme.Spacing.large)
    }

    @ViewBuilder
    private var trackingStatusRow: some View {
        switch ar.segmentState {
        case .idle:
            Label("Point camera at the ground", systemImage: "camera.viewfinder")
                .font(Theme.Typography.caption(size: 13))
                .foregroundStyle(.white.opacity(0.7))
        case .initializing:
            HStack(spacing: 6) {
                ProgressView().tint(.white).scaleEffect(0.8)
                Text("Initializing camera…")
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        case .measuring:
            Label("Tracking", systemImage: "checkmark.circle.fill")
                .font(Theme.Typography.caption(size: 13))
                .foregroundStyle(.green)
        case .limited:
            Label("Tracking limited — move slowly", systemImage: "exclamationmark.triangle.fill")
                .font(Theme.Typography.caption(size: 13))
                .foregroundStyle(.yellow)
        case .captured:
            EmptyView()
        }
    }

    private var distanceLabel: some View {
        let value: Double = {
            switch ar.segmentState {
            case .measuring(let d), .limited(let d): return d
            case .captured(let m): return m
            default: return 0
            }
        }()
        return Text(String(format: "%.1f m", value))
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .foregroundStyle(value > 0 ? Theme.Colors.accent : .white.opacity(0.3))
            .monospacedDigit()
    }

    @ViewBuilder
    private var hudControls: some View {
        switch ar.segmentState {
        case .idle:
            accentButton("Start") { ar.start(isFirstSegment: step == .length) }
            backButton
        case .initializing:
            accentButton("Initializing…") {}
                .disabled(true)
            backButton
        case .measuring, .limited:
            accentButton("Stop") { ar.stop() }
        case .captured(let meters):
            if meters >= 5 {
                accentButton(String(format: "Use %.1f m →", meters)) { advance(meters: meters) }
            } else {
                Text("Too short — walk further and try again.")
                    .font(Theme.Typography.caption(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            Button("Redo") { ar.reset() }
                .font(Theme.Typography.body(size: 14))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var backButton: some View {
        Button("Back to methods", action: onBack)
            .font(Theme.Typography.body(size: 14))
            .foregroundStyle(.white.opacity(0.7))
    }

    private func accentButton(_ label: String, action: @escaping () -> Void) -> some View {
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

    private func advance(meters: Double) {
        switch step {
        case .length:
            ar.reset()
            step = .width(length: meters)
        case .width(let length):
            ar.reset()
            step = .confirm(length: length, width: meters)
        default:
            break
        }
    }

    // MARK: - Confirm screen

    private func confirmScreen(length: Double, width: Double) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Label("Measured dimensions", systemImage: "camera.metering.matrix")
                    .font(Theme.Typography.title(size: 20))
                    .foregroundStyle(Theme.Colors.accent)

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
                        .background(Theme.Colors.surface)
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

                Button("Back to methods", action: onBack)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
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
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Saved screen

    private var savedScreen: some View {
        ScrollView {
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
                Button("Back to methods", action: onBack)
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.top, Theme.Spacing.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
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
                    latitude: nil,
                    longitude: nil,
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

// MARK: - AR camera preview (UIViewRepresentable)

private struct ARCameraPreview: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.autoenablesDefaultLighting = false
        view.rendersContinuously = false
        view.showsStatistics = false
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
