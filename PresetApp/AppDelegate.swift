import UIKit

/// 构建与验证关键指令
///
/// - 部署目标：iOS 13.0（IPHONEOS_DEPLOYMENT_TARGET）。
///   任何 iOS 14+ 才有的 API 必须用 `if #available(iOS 14, *)` 守卫，不得直接使用。
/// - 验证环境（非部署目标）：iPhone 12 + iOS 14.5 模拟器。
///   iOS 13 运行时在本机不可达，故以 iOS 14.5 作为最接近部署目标的验证运行时。
/// - 编译：必须用 Xcode 12.5.1 命令行工具链（GUI 不可用）：
///   DEVELOPER_DIR=/Applications/Xcode12.app/Contents/Developer \
///     xcodebuild -project PresetApp.xcodeproj -scheme PresetApp \
///     -destination 'platform=iOS Simulator,id=<iPhone12-UDID>' build
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootShellController()
        window?.makeKeyAndVisible()
        return true
    }
}
