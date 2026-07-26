import UIKit
import SwiftUI

final class PlanStageController: UIHostingController<PlanStage> {
    init() {
        super.init(rootView: PlanStage())
        title = "Plan"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
