import Foundation

/// Pitch-normalized movement data (0…1 on field length/width). GPS lat/lon maps here when available.
enum SessionActivityGeometry {
    /// Standard pitch aspect: 105 m × 68 m.
    static let pitchAspect: CGFloat = 105 / 68

    struct PitchPoint: Equatable {
        let x: Double
        let y: Double
        let weight: Double
    }

    /// Movement path on the pitch derived from session speed samples (or distance fallback).
    static func pitchTrack(from session: SportSession) -> [PitchPoint] {
        guard let samples = session.samples, samples.count >= 2, session.durationS > 0 else {
            return fallbackPath(distanceM: session.distanceM)
        }

        var points: [PitchPoint] = []
        var x = 0.5
        var y = 0.5
        points.append(PitchPoint(x: x, y: y, weight: 0.5))

        let sorted = samples.sorted { $0.tOffsetS < $1.tOffsetS }
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let cur = sorted[i]
            let dt = max(1, cur.tOffsetS - prev.tOffsetS)
            let speedMS = (cur.speedKmh ?? prev.speedKmh ?? 8) / 3.6
            let distM = speedMS * Double(dt)
            let progress = Double(cur.tOffsetS) / Double(session.durationS)
            let heading = -Double.pi / 2 + sin(progress * 4 * .pi) * 0.85
            x += cos(heading) * distM / 105
            y += sin(heading) * distM / 68
            x = min(0.94, max(0.06, x))
            y = min(0.94, max(0.06, y))
            let weight = min(1, (cur.speedKmh ?? 8) / 26)
            points.append(PitchPoint(x: x, y: y, weight: weight))
        }
        return points
    }

    /// Accumulates movement weight on a pitch grid for heatmap rendering.
    static func heatGrid(from track: [PitchPoint], cols: Int = 80, rows: Int = 52) -> [[Float]] {
        var grid = Array(repeating: Array(repeating: Float(0), count: cols), count: rows)
        guard !track.isEmpty else { return grid }

        for point in track {
            let col = Int(point.x * Double(cols - 1))
            let row = Int(point.y * Double(rows - 1))
            let splatRadius = 3
            for dr in -splatRadius...splatRadius {
                for dc in -splatRadius...splatRadius {
                    let r = row + dr
                    let c = col + dc
                    guard r >= 0, r < rows, c >= 0, c < cols else { continue }
                    let falloff = Float(max(0, 1 - hypot(Double(dr), Double(dc)) / Double(splatRadius + 1)))
                    grid[r][c] += Float(point.weight) * falloff
                }
            }
        }
        return grid
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

    private static func fallbackPath(distanceM: Double) -> [PitchPoint] {
        let steps = 32
        let radiusX = min(0.38, distanceM / 105 / 4)
        let radiusY = radiusX * 68 / 105
        return (0...steps).map { i in
            let t = Double(i) / Double(steps) * 2 * .pi
            return PitchPoint(
                x: 0.5 + cos(t) * radiusX,
                y: 0.5 + sin(t) * radiusY,
                weight: 0.45
            )
        }
    }
}
