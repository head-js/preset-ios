import SwiftUI

final class ProfilePage: UIHostingController<ProfilePage.View> {
    init(onGotoPlan: @escaping () -> Void) {
        super.init(rootView: View(onGotoPlan: onGotoPlan))
        rootView.onLoginRequested = { [weak self] onLogin in
            self?.requestLogin(onLogin: onLogin)
        }
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func requestLogin(onLogin: @escaping (String) -> Void) {
        guard let rootShell = view.window?.rootViewController as? RootShell else {
            return
        }

        rootShell.showLogin(onLogin: onLogin)
    }
}
