import SwiftUI

extension TaskPage {
    struct View: SwiftUI.View {
        let onGotoPlan: () -> Void

        var body: some SwiftUI.View {
            VStack(spacing: 16) {
                Text("Task Page")
                    .font(.title)
                Button("Back to Plan", action: onGotoPlan)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
