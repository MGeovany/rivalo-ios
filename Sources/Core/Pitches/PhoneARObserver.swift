import ARKit
import Foundation
import Observation

/// Tracks walking distance via ARKit visual odometry (camera + IMU).
/// More accurate than GPS for pitch-scale distances. No internet or satellite needed.
///
/// Pattern mirrors PitchWalkMeasureService on watchOS:
/// @MainActor class, nonisolated delegate callbacks → Task { @MainActor in }.
@Observable
@MainActor
final class PhoneARObserver: NSObject {
    enum SegmentState: Equatable {
        case idle
        case initializing          // session started, waiting for first good tracking
        case measuring(distance: Double)
        case limited(distance: Double)  // degraded tracking — still accumulating
        case captured(meters: Double)
    }

    var segmentState: SegmentState = .idle
    /// Position of the first tracked frame — used as pitch lat/lon (not available from AR, nil always).
    private(set) var pitchLocation: Void? = nil // AR has no GPS coords

    let session = ARSession()
    private var lastPosition: SIMD3<Float>?
    private var isActive = false

    override init() {
        super.init()
        session.delegate = self
    }

    var isAuthorized: Bool { true } // camera permission handled by Info.plist + OS prompt

    func start(isFirstSegment: Bool = false) {
        lastPosition = nil
        isActive = true
        segmentState = .initializing

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        isActive = false
        session.pause()
        switch segmentState {
        case .measuring(let d), .limited(let d): segmentState = .captured(meters: max(d, 0))
        default: segmentState = .captured(meters: 0)
        }
    }

    func reset() {
        isActive = false
        session.pause()
        lastPosition = nil
        segmentState = .idle
    }
}

// MARK: - ARSessionDelegate

extension PhoneARObserver: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let col = frame.camera.transform.columns.3
        let position = SIMD3<Float>(col.x, col.y, col.z)
        let quality: TrackingQuality
        switch frame.camera.trackingState {
        case .normal:        quality = .good
        case .limited:       quality = .limited
        case .notAvailable:  quality = .unavailable
        }
        Task { @MainActor in
            guard isActive else { return }
            accumulate(position: position, quality: quality)
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: any Error) {
        Task { @MainActor in
            if isActive { segmentState = .initializing }
        }
    }
}

// MARK: - Private

private extension PhoneARObserver {
    enum TrackingQuality: Sendable { case good, limited, unavailable }

    func accumulate(position: SIMD3<Float>, quality: TrackingQuality) {
        guard quality != .unavailable else {
            lastPosition = nil
            if case .initializing = segmentState {} else { segmentState = .initializing }
            return
        }

        guard let last = lastPosition else {
            lastPosition = position
            segmentState = quality == .good ? .measuring(distance: 0) : .limited(distance: 0)
            return
        }

        let delta = Double(simd_distance(position, last))
        lastPosition = position

        // Ignore micro-jitter and implausible teleports
        guard delta >= 0.05, delta < 3 else { return }

        let current: Double
        switch segmentState {
        case .measuring(let d), .limited(let d): current = d
        default: current = 0
        }
        let next = current + delta
        segmentState = quality == .good ? .measuring(distance: next) : .limited(distance: next)
    }
}
