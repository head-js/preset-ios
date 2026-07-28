import SwiftUI

final class LoginPage: UIHostingController<LoginPage.View> {
    init(
        onLogin: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        super.init(
            rootView: View(
                onLogin: onLogin,
                onCancel: onCancel
            )
        )
        title = "Log In"
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
