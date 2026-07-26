import SwiftUI

struct TaskPage: View {
    let onGotoPlan: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Task Page")
                .font(.title)
            Button("Back to Plan", action: onGotoPlan)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
