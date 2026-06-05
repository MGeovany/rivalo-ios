#if DEBUG
import SwiftUI

@MainActor
@Observable
final class WatchDebugState {
    static let shared = WatchDebugState()
    private init() {}

    var pendingCount: Int = 0
    var log: [LogEntry] = []

    struct LogEntry: Identifiable {
        let id = UUID()
        let time: String
        let message: String
        let level: Level

        enum Level { case info, success, error, warning }
    }

    func append(_ message: String, level: LogEntry.Level = .info) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        log.append(LogEntry(time: formatter.string(from: Date()), message: message, level: level))
        if log.count > 6 { log.removeFirst() }
    }
}

struct WatchDebugOverlay: View {
    @State private var debug = WatchDebugState.shared
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("WATCH DEBUG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                    Spacer()
                    Text("Queue: \(debug.pendingCount)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(debug.pendingCount > 0 ? .orange : .gray)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(.gray.opacity(0.3))

                if debug.log.isEmpty {
                    Text("No events yet")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(debug.log) { entry in
                            HStack(alignment: .top, spacing: 4) {
                                Text(entry.time)
                                    .foregroundStyle(.gray)
                                Text(entry.message)
                                    .foregroundStyle(entryColor(entry.level))
                            }
                            .font(.system(size: 10, design: .monospaced))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
            }
        }
        .background(.black.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
    }

    private func entryColor(_ level: WatchDebugState.LogEntry.Level) -> Color {
        switch level {
        case .info: .white
        case .success: .green
        case .error: .red
        case .warning: .orange
        }
    }
}
#endif
