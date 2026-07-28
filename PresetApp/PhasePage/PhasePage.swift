import SwiftUI

final class PhasePage: UIHostingController<PhasePage.View> {
    init(onGotoPlan: @escaping () -> Void) {
        super.init(rootView: View(onGotoPlan: onGotoPlan))
        title = "Phase"
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
