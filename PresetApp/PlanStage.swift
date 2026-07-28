import UIKit

final class PlanStage: UITabBarController {
    private enum PageIndex: Int {
        case plan
        case phase
        case task
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.isHidden = true
        viewControllers = makePageControllers()
        show(.plan)
    }

    private func makePageControllers() -> [UIViewController] {
        let planPage = PlanPage(
            onGotoPhase: { [weak self] in
                self?.show(.phase)
            },
            onGotoTask: { [weak self] in
                self?.show(.task)
            }
        )

        let phasePage = PhasePage { [weak self] in
            self?.show(.plan)
        }

        let taskPage = TaskPage { [weak self] in
            self?.show(.plan)
        }

        return [
            planPage,
            phasePage,
            taskPage
        ]
    }

    private func show(_ page: PageIndex) {
        selectedIndex = page.rawValue
        navigationItem.title = selectedViewController?.title
    }
}
