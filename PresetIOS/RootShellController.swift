import UIKit

final class RootShellController: UIViewController {
    private let stageNavigationController: UINavigationController

    init() {
        let mainStageController = MainStageController()
        self.stageNavigationController = UINavigationController(rootViewController: mainStageController)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(stageNavigationController)
        view.addSubview(stageNavigationController.view)
        stageNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stageNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stageNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stageNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            stageNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        stageNavigationController.didMove(toParent: self)
    }
}
