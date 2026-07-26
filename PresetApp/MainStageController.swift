import UIKit
import SwiftUI
import PresetDeviceInfo

final class ConnectivityHelperBox {
    let helper = ConnectivityHelper()
}

final class WebViewHelperBox {
    let helper = WebViewHelper()
    var hasLoadedInitialURL = false
}

final class MainStageDependencies {
    let connectivityHelper = ConnectivityHelperBox()
    let deviceIdentityRepository = DeviceIdentityRepository()
    let deviceInfoRepository = DeviceInfoRepository()
    let appInfoRepository = AppInfoRepository()
    let webViewHelper = WebViewHelperBox()
}

final class MainStageController: UIHostingController<MainStage> {
    private let dependencies = MainStageDependencies()

    init() {
        super.init(rootView: MainStage(dependencies: dependencies, onGotoPlan: {}))
        rootView = MainStage(
            dependencies: dependencies,
            onGotoPlan: { [weak self] in
                self?.showPlanStage()
            }
        )
        title = "Main"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showPlanStage() {
        navigationController?.pushViewController(PlanStageController(), animated: true)
    }
}
