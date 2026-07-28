import SwiftUI

final class PlanPage: UIHostingController<PlanPage.View> {
    init(
        onGotoPhase: @escaping () -> Void,
        onGotoTask: @escaping () -> Void
    ) {
        super.init(
            rootView: View(
                onGotoPhase: onGotoPhase,
                onGotoTask: onGotoTask
            )
        )
        title = "Plan"
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
