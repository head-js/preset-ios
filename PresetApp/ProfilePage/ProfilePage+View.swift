import SwiftUI

extension ProfilePage {
    struct View: SwiftUI.View {
        let onGotoPlan: () -> Void
        var onLoginRequested: ((@escaping (String) -> Void) -> Void)? = nil

        private let tokenStorage = TokenStorage()

        @State private var username: String?

        var body: some SwiftUI.View {
            VStack(spacing: 24) {
                Text("Profile")
                    .font(.title)

                if let username = username {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(username)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)

                    Button(action: logout) {
                        Text("Log Out")
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                } else {
                    Button(action: requestLogin) {
                        Text("Log In")
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                }

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
            .onAppear(perform: loadLoginState)
        }

        private func requestLogin() {
            onLoginRequested? { username in
                let token = UUID().uuidString
                tokenStorage.saveToken(token, username: username)
                self.username = username
            }
        }

        private func loadLoginState() {
            if tokenStorage.isLoggedIn(),
               let storedUsername = tokenStorage.getUsername(),
               !storedUsername.isEmpty {
                username = storedUsername
            } else {
                if tokenStorage.isLoggedIn() {
                    tokenStorage.clear()
                }
                username = nil
            }
        }

        private func logout() {
            tokenStorage.clear()
            username = nil
        }
    }
}
