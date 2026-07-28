import Foundation

final class TokenStorage {
    private let storage: UserDefaults

    private let tokenKey = "auth_token"
    private let usernameKey = "auth_username"

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    func saveToken(_ token: String, username: String) {
        storage.set(token, forKey: tokenKey)
        storage.set(username, forKey: usernameKey)
    }

    func getToken() -> String? {
        storage.string(forKey: tokenKey)
    }

    func getUsername() -> String? {
        storage.string(forKey: usernameKey)
    }

    func clear() {
        storage.removeObject(forKey: tokenKey)
        storage.removeObject(forKey: usernameKey)
    }

    func isLoggedIn() -> Bool {
        getToken() != nil
    }
}
