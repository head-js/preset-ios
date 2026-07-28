import SwiftUI

final class TaskPage: UIHostingController<TaskPage.View> {
    init(onGotoPlan: @escaping () -> Void) {
        super.init(rootView: View(onGotoPlan: onGotoPlan))
        title = "Task"
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
