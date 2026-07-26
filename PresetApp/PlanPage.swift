import SwiftUI

struct PlanPage: View {
    let onGotoPhase: () -> Void
    let onGotoTask: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Plan Page")
                .font(.title)
            Button("Goto Phase", action: onGotoPhase)
            Button("Goto Task", action: onGotoTask)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
