import UIKit

private final class ArrowOnlyNavigationController: UINavigationController {
    override func pushViewController(
        _ viewController: UIViewController,
        animated: Bool
    ) {
        topViewController?.navigationItem.backButtonDisplayMode = .minimal
        super.pushViewController(viewController, animated: animated)
    }
}

final class RootShell: UIViewController {
    private let pageNavCtrl: UINavigationController

    init() {
        let mainStage = MainStage()
        self.pageNavCtrl = ArrowOnlyNavigationController(
            rootViewController: mainStage
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pageNavCtrl)
        view.addSubview(pageNavCtrl.view)
        pageNavCtrl.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageNavCtrl.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageNavCtrl.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageNavCtrl.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageNavCtrl.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pageNavCtrl.didMove(toParent: self)
    }

    func showLogin(onLogin: @escaping (String) -> Void) {
        guard presentedViewController == nil else { return }

        let loginPage = LoginPage(
            onLogin: { [weak self] username in
                onLogin(username)
                self?.dismiss(animated: true)
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        loginPage.modalPresentationStyle = .fullScreen
        present(loginPage, animated: true)
    }
}
