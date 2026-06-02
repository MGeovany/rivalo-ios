import SwiftUI

/// Interactive pitch map: heatmap (default), GPS route, or sprint bursts.
struct PitchMapView: View {
    let session: SportSession
    /// Hides the bottom info card (e.g. embedded in latest-match card).
    var showsInfoCard: Bool = true

    @State private var mapMode: PitchMapMode = .heatmap
    @State private var matchPeriod: PitchMatchPeriod = .full
    @State private var heatImage: UIImage?

    private var format: PitchFormat {
        SessionActivityGeometry.pitchFormat(for: session)
    }

    private var track: [SessionActivityGeometry.PitchPoint] {
        SessionActivityGeometry.pitchTrack(from: session, period: matchPeriod, format: format)
    }

    private var sprintSegments: [(SessionActivityGeometry.PitchPoint, SessionActivityGeometry.PitchPoint)] {
        SessionActivityGeometry.sprintSegments(from: session, period: matchPeriod, format: format)
    }

    var body: some View {
        PitchMapPanel {
            PitchSegmentedControl(selection: $mapMode, items: PitchMapMode.allCases)

            PitchSegmentedControl(selection: $matchPeriod, items: PitchMatchPeriod.allCases)

            PitchAttackDirectionView()

            pitchCanvas
                .aspectRatio(format.aspect, contentMode: .fit)
                .frame(maxWidth: .infinity)

            if mapMode == .heatmap {
                PitchHeatmapLegend()
            }

            if showsInfoCard {
                PitchMapInfoCard(
                    title: infoTitle,
                    subtitle: infoSubtitle,
                    icon: infoIcon
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: mapMode)
        .animation(.easeInOut(duration: 0.2), value: matchPeriod)
        .task(id: "\(renderKey)-\(mapMode.rawValue)") {
            await renderHeatmap()
        }
    }

    private var renderKey: String {
        "\(session.id)-\(matchPeriod.rawValue)-\(track.count)"
    }

    private var infoTitle: String {
        switch mapMode {
        case .heatmap: "Heatmap shows player activity"
        case .route: "Route shows your movement path"
        case .sprints: "Sprints highlight high-speed bursts"
        }
    }

    private var infoSubtitle: String {
        switch mapMode {
        case .heatmap: "Red areas indicate the most time spent on the pitch"
        case .route: "Orange line traces your path across the pitch for this period"
        case .sprints: "Bright segments mark runs above \(Int(SessionActivityGeometry.sprintSpeedThresholdKmh)) km/h"
        }
    }

    private var infoIcon: String {
        switch mapMode {
        case .heatmap: "figure.run"
        case .route: "point.topleft.down.to.point.bottomright.curvepath"
        case .sprints: "bolt.fill"
        }
    }

    private var pitchCanvas: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                PitchFieldCanvas(format: format)

                if mapMode == .heatmap, let heatImage {
                    Image(uiImage: heatImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .blendMode(.plusLighter)
                        .opacity(0.95)
                        .allowsHitTesting(false)
                }

                if mapMode == .route {
                    routePath(in: size)
                }

                if mapMode == .sprints {
                    sprintOverlay(in: size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
        }
    }

    @MainActor
    private func renderHeatmap() async {
        guard mapMode == .heatmap else { return }
        let width: CGFloat = 640
        let height = width / format.aspect
        heatImage = PitchHeatmapEngine.renderHeatLayer(
            track: track,
            size: CGSize(width: width, height: height)
        )
    }

    private func routePath(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            guard track.count >= 2 else { return }
            var path = Path()
            for (index, point) in track.enumerated() {
                let pt = CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
                if index == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
            context.stroke(
                path,
                with: .color(Theme.Colors.accent),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            if let first = track.first {
                let start = CGPoint(x: first.x * canvasSize.width, y: first.y * canvasSize.height)
                context.fill(
                    Path(ellipseIn: CGRect(x: start.x - 4, y: start.y - 4, width: 8, height: 8)),
                    with: .color(.white.opacity(0.9))
                )
            }
            if let last = track.last {
                let end = CGPoint(x: last.x * canvasSize.width, y: last.y * canvasSize.height)
                context.fill(
                    Path(ellipseIn: CGRect(x: end.x - 5, y: end.y - 5, width: 10, height: 10)),
                    with: .color(Theme.Colors.accentBright)
                )
            }
        }
    }

    private func sprintOverlay(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for (from, to) in sprintSegments {
                var path = Path()
                let p0 = CGPoint(x: from.x * canvasSize.width, y: from.y * canvasSize.height)
                let p1 = CGPoint(x: to.x * canvasSize.width, y: to.y * canvasSize.height)
                path.move(to: p0)
                path.addLine(to: p1)
                context.stroke(
                    path,
                    with: .color(Color(red: 1, green: 0.85, blue: 0.35)),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
            }

            for point in track where point.isSprint {
                let center = CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7)),
                    with: .color(.white)
                )
            }
        }
    }
}

/// Pitch lines adapted to 5 / 7 / 9 / 11-a-side (horizontal, attack → right).
struct PitchFieldCanvas: View {
    let format: PitchFormat

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let line = GraphicsContext.Shading.color(PitchMapStyle.pitchLine)
            let inset: CGFloat = 3

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [PitchMapStyle.pitchGreenTop, PitchMapStyle.pitchGreenBottom]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: w, y: h)
                )
            )

            strokeBox(context: &context, rect: CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2), line: line, width: 1.5)

            var halfway = Path()
            halfway.move(to: CGPoint(x: w / 2, y: inset))
            halfway.addLine(to: CGPoint(x: w / 2, y: h - inset))
            context.stroke(halfway, with: line, lineWidth: 1.2)

            if format.showsCenterCircle {
                let circleR = min(w, h) * format.centerCircleRadiusRatio
                context.stroke(
                    Path(ellipseIn: CGRect(x: w / 2 - circleR, y: h / 2 - circleR, width: circleR * 2, height: circleR * 2)),
                    with: line,
                    lineWidth: 1.2
                )
            }

            let spotR: CGFloat = 2.5
            context.fill(
                Path(ellipseIn: CGRect(x: w / 2 - spotR, y: h / 2 - spotR, width: spotR * 2, height: spotR * 2)),
                with: line
            )

            let boxW = w * format.penaltyBoxDepthRatio
            let boxH = h * format.penaltyBoxWidthRatio
            strokeBox(
                context: &context,
                rect: CGRect(x: inset, y: (h - boxH) / 2, width: boxW, height: boxH),
                line: line,
                width: 1
            )
            strokeBox(
                context: &context,
                rect: CGRect(x: w - boxW - inset, y: (h - boxH) / 2, width: boxW, height: boxH),
                line: line,
                width: 1
            )

            if format.showsGoalAreas {
                let goalW = boxW * 0.42
                let goalH = boxH * 0.52
                strokeBox(
                    context: &context,
                    rect: CGRect(x: inset, y: (h - goalH) / 2, width: goalW, height: goalH),
                    line: line,
                    width: 0.9
                )
                strokeBox(
                    context: &context,
                    rect: CGRect(x: w - goalW - inset, y: (h - goalH) / 2, width: goalW, height: goalH),
                    line: line,
                    width: 0.9
                )
            }
        }
    }

    private func strokeBox(
        context: inout GraphicsContext,
        rect: CGRect,
        line: GraphicsContext.Shading,
        width: CGFloat
    ) {
        context.stroke(Path(rect), with: line, lineWidth: width)
    }
}
