import SwiftUI

/// Back-compat wrapper — use `PitchMapView` for the full interactive map.
struct PitchMovementView: View {
    let session: SportSession
    var showCaption = false

    var body: some View {
        PitchMapView(session: session, compact: !showCaption)
    }
}
