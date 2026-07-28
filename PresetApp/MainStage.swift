import UIKit

final class MainStage: UITabBarController, UITabBarControllerDelegate {
    private let billActionController = UIViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        viewControllers = makeBottomNavigationControllers()
        selectedIndex = 0
        navigationItem.title = "Home"
    }

    private func makeBottomNavigationControllers() -> [UIViewController] {
        let homePage = HomePage()
        homePage.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        billActionController.tabBarItem = UITabBarItem(
            title: "Bill",
            image: UIImage(systemName: "doc.text"),
            selectedImage: UIImage(systemName: "doc.text.fill")
        )

        let webViewPage = WebViewPage()
        webViewPage.tabBarItem = UITabBarItem(
            title: "WebView",
            image: UIImage(systemName: "globe"),
            selectedImage: UIImage(systemName: "globe")
        )

        let profilePage = ProfilePage(
            onGotoPlan: { [weak self] in
                self?.showPlanPage()
            }
        )
        profilePage.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        return [
            homePage,
            billActionController,
            webViewPage,
            profilePage
        ]
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard viewController === billActionController else {
            return true
        }

        showBillPage()
        return false
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        navigationItem.title = viewController.tabBarItem.title
    }

    private func showBillPage() {
        guard let navigationController = navigationController,
              navigationController.topViewController === self else {
            return
        }

        navigationController.pushViewController(BillPage(), animated: true)
    }

    private func showPlanPage() {
        navigationController?.pushViewController(
            PlanStage(),
            animated: true
        )
    }
}
