import UIKit

/// 构建与验证关键指令
///
/// - 最低兼容目标：iPhone 12 + iOS 14（IPHONEOS_DEPLOYMENT_TARGET = 14.0）。
///   任何 iOS 15+ 才有的 API 必须使用可用性守卫，并提供 iOS 14 兼容路径。
/// - 本机验证环境：iPhone 12 + iOS 14.5 模拟器。
///   Xcode 12.5.1 官方 bundle 实际提供的 iOS 14 系列运行时为 14.5。
/// - 编译：必须用 Xcode 12.5.1 命令行工具链（GUI 不可用）：
///   DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer \
///     xcodebuild -workspace PresetApp.xcworkspace -scheme PresetApp \
///     -destination 'platform=iOS Simulator,id=<iPhone12-UDID>' build
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 用于验证系统 Launch Screen 与应用 Splash Screen 的交接。
        // Debug 和 Release 均保持系统 Launch Screen 2 秒。
        Thread.sleep(forTimeInterval: 2)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = SplashViewController { [weak self] in
            self?.showMain()
        }
        window?.makeKeyAndVisible()
        return true
    }

    private func showMain() {
        window?.rootViewController = RootShellController()
    }
}
