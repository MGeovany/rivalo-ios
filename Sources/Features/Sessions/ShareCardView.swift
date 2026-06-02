import SwiftUI

struct ShareCardView: View {
    let session: SportSession
    let meta: SessionMeta

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.1))
            statsGrid
            if let drop = session.fatigueDrop {
                Divider().overlay(Color.white.opacity(0.1))
                fatigueRow(drop)
            }
            Divider().overlay(Color.white.opacity(0.1))
            contextRow
        }
        .frame(width: 340)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.05, green: 0.05, blue: 0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 1, green: 0.35, blue: 0).opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("RIVALO")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 1, green: 0.35, blue: 0))
            Text(session.startedAt, style: .date)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
            if let venue = meta.venueName {
                Text(venue)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 20)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            statCell(value: formattedDistance, label: "Distance")
            statCell(value: formattedDuration, label: "Duration")
            statCell(value: formattedSprints, label: "Sprints")
            if let intensity = session.intensity {
                statCell(value: String(format: "%.0f", intensity), label: "Intensity")
            }
            if let rating = session.matchRating {
                statCell(value: String(format: "%.0f", rating), label: "Rating")
            }
            if let speed = session.speedMaxKmh {
                statCell(value: String(format: "%.1f", speed), label: "Top Speed")
            }
            if let cal = session.caloriesKcal {
                statCell(value: "\(Int(cal))", label: "Calories")
            }
            if let hr = session.hrMax {
                statCell(value: "\(hr)", label: "Max HR")
            }
        }
        .padding(20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func fatigueRow(_ drop: FatigueDrop) -> some View {
        HStack(spacing: 24) {
            VStack(spacing: 2) {
                Text(String(format: "%.1f", drop.firstHalf.distanceM / 1000))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("1st Half km")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            VStack(spacing: 2) {
                Text(String(format: "%.1f", drop.secondHalf.distanceM / 1000))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("2nd Half km")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            VStack(spacing: 2) {
                Text(String(format: "%.0f%%", drop.dropPercentage * 100))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(drop.dropPercentage > 0.15 ? Color(red: 0.95, green: 0.3, blue: 0.3) : Color(red: 0, green: 0.85, blue: 0.45))
                Text("Drop")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 16)
    }

    private var contextRow: some View {
        HStack(spacing: 12) {
            if let mt = session.matchType {
                contextChip(mt)
            }
            if let sf = session.surface {
                contextChip(sf)
            }
            if let pos = session.position {
                contextChip(pos)
            }
            if let result = session.result {
                contextChip(result)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func contextChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
    }

    private var formattedDistance: String {
        let km = session.distanceM / 1000
        return String(format: "%.2f", km)
    }

    private var formattedDuration: String {
        let h = session.durationS / 3600
        let m = (session.durationS % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var formattedSprints: String {
        "\(session.sprints)"
    }
}
