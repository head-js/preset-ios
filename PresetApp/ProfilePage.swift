import SwiftUI

struct ProfilePage: View {
    let onGotoPlan: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Profile")
                .font(.title)
            Button(action: onGotoPlan) {
                Text("Goto Plan")
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
