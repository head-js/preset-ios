import Foundation

struct AppInfo {
    let app_name: DeviceInfoEntry
    let package_name: DeviceInfoEntry
    let version_name: DeviceInfoEntry
    let version_code: DeviceInfoEntry
}

final class AppInfoCollector {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func collect() -> AppInfo {
        AppInfo(
            app_name: DeviceInfoEntry(
                key: "app_name",
                value: readAppName(),
                label: "App Name"
            ),
            package_name: DeviceInfoEntry(
                key: "package_name",
                value: readPackageName(),
                label: "Package Name"
            ),
            version_name: DeviceInfoEntry(
                key: "version_name",
                value: readVersionName(),
                label: "Version Name"
            ),
            version_code: DeviceInfoEntry(
                key: "version_code",
                value: readVersionCode(),
                label: "Version Code"
            )
        )
    }

    private func readAppName() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }

    private func readPackageName() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
    }

    private func readVersionName() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func readVersionCode() -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

}
