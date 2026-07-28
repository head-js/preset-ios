import SwiftUI

extension LoginPage {
    struct View: SwiftUI.View {
        let onLogin: (String) -> Void
        let onCancel: () -> Void

        @State private var usernameInput: String = ""
        @State private var passwordInput: String = ""

        private var canSubmit: Bool {
            !usernameInput.isEmpty && !passwordInput.isEmpty
        }

        var body: some SwiftUI.View {
            VStack(spacing: 24) {
                Text("Log In")
                    .font(.title)

                TextField("Username", text: $usernameInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 24)

                SecureField("Password", text: $passwordInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 24)

                Button(action: {
                    onLogin(usernameInput)
                }) {
                    Text("Log In")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 24)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
