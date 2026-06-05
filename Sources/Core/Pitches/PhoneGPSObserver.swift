import CoreLocation
import Foundation
import Observation

/// Tracks GPS distance while the user walks one edge of the pitch.
/// Mirrors the pattern used by PitchWalkMeasureService on watchOS:
/// @MainActor class, nonisolated delegate callbacks that hop back via Task { @MainActor in }.
@Observable
@MainActor
final class PhoneGPSObserver: NSObject {
    enum SegmentState: Equatable {
        case idle
        case waitingForFix
        case measuring(distance: Double)
        case captured(meters: Double)
    }

    var segmentState: SegmentState = .idle
    var authStatus: CLAuthorizationStatus = .notDetermined
    /// First accurate location received — used as the pitch's lat/lon.
    private(set) var pitchLocation: CLLocation?

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        authStatus = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Starts accumulating distance for a new segment.
    /// Pass `isFirstSegment: true` to also reset the stored pitch location.
    func start(isFirstSegment: Bool = false) {
        guard isAuthorized else { return }
        if isFirstSegment { pitchLocation = nil }
        lastLocation = nil
        segmentState = .waitingForFix
        manager.startUpdatingLocation()
    }

    /// Stops the active segment and freezes the accumulated distance.
    func stop() {
        manager.stopUpdatingLocation()
        switch segmentState {
        case .measuring(let d): segmentState = .captured(meters: max(d, 0))
        case .waitingForFix: segmentState = .captured(meters: 0)
        default: break
        }
    }

    /// Clears segment state back to idle so a new segment can begin.
    func reset() {
        manager.stopUpdatingLocation()
        lastLocation = nil
        segmentState = .idle
    }
}

// MARK: - CLLocationManagerDelegate

extension PhoneGPSObserver: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authStatus = status
            if !isAuthorized { self.manager.stopUpdatingLocation() }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last,
              location.horizontalAccuracy > 0,
              location.horizontalAccuracy < 25 else { return }
        Task { @MainActor in
            if pitchLocation == nil {
                pitchLocation = location
            }
            guard let last = lastLocation else {
                lastLocation = location
                segmentState = .measuring(distance: 0)
                return
            }
            let delta = location.distance(from: last)
            lastLocation = location
            guard delta >= 0.5 else { return }
            let accumulated: Double
            if case .measuring(let d) = segmentState { accumulated = d } else { accumulated = 0 }
            segmentState = .measuring(distance: accumulated + delta)
        }
    }
}
