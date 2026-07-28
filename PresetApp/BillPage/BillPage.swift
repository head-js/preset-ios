import SwiftUI

final class BillPage: UIHostingController<BillPage.View> {
    init() {
        super.init(rootView: View())
        title = "Bill"
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
