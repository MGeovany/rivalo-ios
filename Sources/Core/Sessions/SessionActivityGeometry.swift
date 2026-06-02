import Foundation

/// Pitch-normalized movement data (0…1 on field length/width).
enum SessionActivityGeometry {
    static let sprintSpeedThresholdKmh = 20.0

    struct PitchPoint: Equatable {
        let x: Double
        let y: Double
        let weight: Double
        var isSprint: Bool = false
    }

    static func pitchFormat(for session: SportSession) -> PitchFormat {
        PitchFormat.from(matchType: session.matchType)
    }

    static func pitchAspect(for session: SportSession) -> CGFloat {
        pitchFormat(for: session).aspect
    }

    /// Samples for the selected match period.
    static func samples(for session: SportSession, period: PitchMatchPeriod) -> [SessionSample] {
        guard let samples = session.samples, !samples.isEmpty else { return [] }
        let sorted = samples.sorted { $0.tOffsetS < $1.tOffsetS }

        switch period {
        case .full:
            return sorted
        case .firstHalf:
            let byHalf = sorted.filter { $0.half == 1 }
            if !byHalf.isEmpty { return byHalf }
            if let offset = session.halftimeOffsetS, offset > 0 {
                return sorted.filter { $0.tOffsetS < offset }
            }
            let mid = session.durationS / 2
            return sorted.filter { $0.tOffsetS <= mid }
        case .secondHalf:
            let byHalf = sorted.filter { $0.half == 2 }
            if !byHalf.isEmpty { return byHalf }
            if let offset = session.halftimeOffsetS, offset > 0 {
                return sorted.filter { $0.tOffsetS >= offset }
            }
            let mid = session.durationS / 2
            return sorted.filter { $0.tOffsetS > mid }
        }
    }

    /// Movement path on the pitch for a period and format.
    static func pitchTrack(
        from session: SportSession,
        period: PitchMatchPeriod = .full,
        format: PitchFormat? = nil
    ) -> [PitchPoint] {
        let format = format ?? pitchFormat(for: session)
        let filtered = samples(for: session, period: period)

        if filtered.count >= 2, session.durationS > 0 {
            return track(from: filtered, durationS: session.durationS, format: format)
        }

        let scale = period == .full ? 1.0 : 0.55
        return fallbackPath(distanceM: session.distanceM * scale, format: format)
    }

    /// Sprint segments (pairs of points) for overlay.
    static func sprintSegments(
        from session: SportSession,
        period: PitchMatchPeriod = .full,
        format: PitchFormat? = nil
    ) -> [(PitchPoint, PitchPoint)] {
        let track = pitchTrack(from: session, period: period, format: format)
        guard track.count >= 2 else { return [] }

        var segments: [(PitchPoint, PitchPoint)] = []
        for index in 1..<track.count {
            let prev = track[index - 1]
            let cur = track[index]
            if prev.isSprint || cur.isSprint {
                segments.append((prev, cur))
            }
        }
        return segments
    }

    /// Accumulates movement weight on a pitch grid for heatmap rendering.
    static func heatGrid(from track: [PitchPoint], cols: Int = 96, rows: Int = 64) -> [[Float]] {
        var grid = Array(repeating: Array(repeating: Float(0), count: cols), count: rows)
        guard !track.isEmpty else { return grid }

        let densified = densifyTrack(track, stepsPerSegment: 6)
        let splatRadius = 9

        func splat(x: Double, y: Double, weight: Float) {
            let colCenter = x * Double(cols - 1)
            let rowCenter = y * Double(rows - 1)
            for dr in -splatRadius...splatRadius {
                for dc in -splatRadius...splatRadius {
                    let r = Int(rowCenter) + dr
                    let c = Int(colCenter) + dc
                    guard r >= 0, r < rows, c >= 0, c < cols else { continue }
                    let dist = hypot(Double(dr), Double(dc))
                    let falloff = Float(max(0, 1 - dist / Double(splatRadius)))
                    grid[r][c] += weight * falloff * falloff
                }
            }
        }

        for point in densified {
            splat(x: point.x, y: point.y, weight: Float(max(0.35, point.weight)))
        }
        return grid
    }

    /// Inserts points along each segment so the heatmap is continuous, not sparse dots.
    private static func densifyTrack(_ track: [PitchPoint], stepsPerSegment: Int) -> [PitchPoint] {
        guard track.count >= 2 else { return track }
        var result: [PitchPoint] = []
        result.reserveCapacity(track.count * stepsPerSegment)

        for index in 1..<track.count {
            let from = track[index - 1]
            let to = track[index]
            for step in 0..<stepsPerSegment {
                let t = Double(step) / Double(stepsPerSegment)
                result.append(PitchPoint(
                    x: from.x + (to.x - from.x) * t,
                    y: from.y + (to.y - from.y) * t,
                    weight: from.weight + (to.weight - from.weight) * t,
                    isSprint: from.isSprint || to.isSprint
                ))
            }
        }
        if let last = track.last {
            result.append(last)
        }
        return result
    }

    static func displayLocation(session: SportSession, meta: SessionMeta) -> String {
        if let name = meta.venueName, !name.isEmpty { return name }
        return session.source == "watch" ? "Watch session" : "Manual session"
    }

    static func shareText(session: SportSession, meta: SessionMeta) -> String {
        let place = displayLocation(session: session, meta: meta)
        let date = session.startedAt.formatted(date: .abbreviated, time: .shortened)
        var lines = ["Rivalo match", date, place, session.distanceKmText, session.durationText]
        if let hr = session.hrAvg { lines.append("Avg HR \(hr) bpm") }
        if let intensity = session.intensity { lines.append(String(format: "Intensity %.0f", intensity)) }
        lines.append("Sprints \(session.sprints)")
        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private static func track(
        from samples: [SessionSample],
        durationS: Int,
        format: PitchFormat
    ) -> [PitchPoint] {
        var points: [PitchPoint] = []
        var x = 0.5
        var y = 0.5
        let lengthM = format.lengthM
        let widthM = format.widthM

        let firstSpeed = samples[0].speedKmh ?? 8
        points.append(PitchPoint(
            x: x, y: y,
            weight: min(1, firstSpeed / 26),
            isSprint: firstSpeed >= sprintSpeedThresholdKmh
        ))

        for index in 1..<samples.count {
            let prev = samples[index - 1]
            let cur = samples[index]
            let dt = max(1, cur.tOffsetS - prev.tOffsetS)
            let speedKmh = cur.speedKmh ?? prev.speedKmh ?? 8
            let speedMS = speedKmh / 3.6
            let distM = speedMS * Double(dt)
            let progress = Double(cur.tOffsetS) / Double(max(1, durationS))
            let heading = -Double.pi / 2 + sin(progress * 4 * .pi) * 0.85
            x += cos(heading) * distM / lengthM
            y += sin(heading) * distM / widthM
            x = min(0.94, max(0.06, x))
            y = min(0.94, max(0.06, y))
            let weight = min(1, speedKmh / 26)
            points.append(PitchPoint(
                x: x, y: y,
                weight: weight,
                isSprint: speedKmh >= sprintSpeedThresholdKmh
            ))
        }
        return points
    }

    private static func fallbackPath(distanceM: Double, format: PitchFormat) -> [PitchPoint] {
        let steps = 32
        let radiusX = min(0.38, distanceM / format.lengthM / 4)
        let radiusY = radiusX * format.widthM / format.lengthM
        return (0...steps).map { index in
            let t = Double(index) / Double(steps) * 2 * .pi
            return PitchPoint(x: 0.5 + cos(t) * radiusX, y: 0.5 + sin(t) * radiusY, weight: 0.45)
        }
    }
}
