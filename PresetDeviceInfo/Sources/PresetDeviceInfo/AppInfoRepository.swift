public final class AppInfoRepository {
    private let appInfoCollector = AppInfoCollector()

    public init() {}

    public func getAppInfo() -> [DeviceInfoEntry] {
        let info = appInfoCollector.collect()
        return [
            info.app_name,
            info.package_name,
            info.version_name,
            info.version_code
        ]
    }
}
