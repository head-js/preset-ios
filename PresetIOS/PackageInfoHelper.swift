import Foundation

struct AppPackageInfo {
    let appName: String
    let bundleId: String
    let versionName: String
    let versionCode: String
}

class PackageInfoHelper {

    private(set) var currentInfo: AppPackageInfo = AppPackageInfo(
        appName: "unknown",
        bundleId: "unknown",
        versionName: "unknown",
        versionCode: "unknown"
    )

    func getCurrentAppPackageInfo() -> AppPackageInfo {
        let bundle = Bundle.main
        let appName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "unknown"
        let bundleId = bundle.bundleIdentifier ?? "unknown"
        let versionName = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "unknown"
        let versionCode = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "unknown"
        currentInfo = AppPackageInfo(
            appName: appName,
            bundleId: bundleId,
            versionName: versionName,
            versionCode: versionCode
        )
        return currentInfo
    }

    func getDisplayString() -> String {
        let info = getCurrentAppPackageInfo()
        return "App Name: \(info.appName) | Package Name: \(info.bundleId) | Version Name: \(info.versionName) | Version Code: \(info.versionCode)"
    }
}
