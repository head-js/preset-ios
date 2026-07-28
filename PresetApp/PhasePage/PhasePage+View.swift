import SwiftUI

extension PhasePage {
    struct View: SwiftUI.View {
        let onGotoPlan: () -> Void

        var body: some SwiftUI.View {
            VStack(spacing: 16) {
                Text("Phase Page")
                    .font(.title)
                Button("Back to Plan", action: onGotoPlan)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
