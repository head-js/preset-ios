import SwiftUI

extension PlanPage {
    struct View: SwiftUI.View {
        let onGotoPhase: () -> Void
        let onGotoTask: () -> Void

        var body: some SwiftUI.View {
            VStack(spacing: 16) {
                Text("Plan Page")
                    .font(.title)
                Button("Goto Phase", action: onGotoPhase)
                Button("Goto Task", action: onGotoTask)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
