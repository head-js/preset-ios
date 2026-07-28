import SwiftUI

final class HomePage: UIHostingController<HomePage.View> {
    init() {
        super.init(rootView: View())
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
