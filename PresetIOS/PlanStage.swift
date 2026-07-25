import SwiftUI

struct PlanStage: View {
    enum Page {
        case plan
        case phase
        case task
    }

    @State private var activePage: Page = .plan

    var body: some View {
        VStack(spacing: 16) {
            switch activePage {
            case .plan:
                PlanPage(
                    onGotoPhase: { activePage = .phase },
                    onGotoTask: { activePage = .task }
                )
            case .phase:
                PhasePage(onGotoPlan: { activePage = .plan })
            case .task:
                TaskPage(onGotoPlan: { activePage = .plan })
            }
        }
    }
}
