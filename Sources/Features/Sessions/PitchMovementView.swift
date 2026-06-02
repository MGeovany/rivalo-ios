import SwiftUI

/// Full pitch view: field markings, smooth heat layer, and movement path (no city map).
struct PitchMovementView: View {
    let session: SportSession
    var showCaption = false

    @State private var heatImage: UIImage?

    private var track: [SessionActivityGeometry.PitchPoint] {
        SessionActivityGeometry.pitchTrack(from: session)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                PitchFieldCanvas()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let heatImage {
                    Image(uiImage: heatImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(0.88)
                }

                movementPath(in: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if showCaption {
                    Text("Movement on pitch")
                        .font(Theme.Typography.statLabel(size: 9))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(10)
                }
            }
        }
        .aspectRatio(SessionActivityGeometry.pitchAspect, contentMode: .fit)
        .task(id: session.id) {
            let side = CGSize(width: 560, height: 560 / SessionActivityGeometry.pitchAspect)
            heatImage = PitchHeatmapEngine.renderHeatLayer(session: session, size: side)
        }
    }

    private func movementPath(in size: CGSize) -> some View {
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
            context.stroke(path, with: .color(Theme.Colors.accentBright), lineWidth: 2.5)

            if let last = track.last {
                let end = CGPoint(x: last.x * canvasSize.width, y: last.y * canvasSize.height)
                let dot = CGRect(x: end.x - 4, y: end.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dot), with: .color(.white))
            }
        }
    }
}

/// Standard football pitch lines.
private struct PitchFieldCanvas: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let line = GraphicsContext.Shading.color(.white.opacity(0.28))

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.11, green: 0.36, blue: 0.15),
                        Color(red: 0.07, green: 0.26, blue: 0.10),
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: w, y: h)
                )
            )

            var border = Path(CGRect(x: 2, y: 2, width: w - 4, height: h - 4))
            context.stroke(border, with: line, lineWidth: 1.5)

            var mid = Path()
            mid.move(to: CGPoint(x: w / 2, y: 2))
            mid.addLine(to: CGPoint(x: w / 2, y: h - 2))
            context.stroke(mid, with: line, lineWidth: 1.2)

            let circleR = min(w, h) * 0.12
            context.stroke(
                Path(ellipseIn: CGRect(x: w / 2 - circleR, y: h / 2 - circleR, width: circleR * 2, height: circleR * 2)),
                with: line,
                lineWidth: 1.2
            )

            let boxW = w * 0.16
            let boxH = h * 0.52
            context.stroke(
                Path(CGRect(x: 2, y: (h - boxH) / 2, width: boxW, height: boxH)),
                with: line,
                lineWidth: 1
            )
            context.stroke(
                Path(CGRect(x: w - boxW - 2, y: (h - boxH) / 2, width: boxW, height: boxH)),
                with: line,
                lineWidth: 1
            )
        }
    }
}
