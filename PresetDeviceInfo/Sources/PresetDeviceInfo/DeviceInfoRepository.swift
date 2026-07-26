public final class DeviceInfoRepository {
    private let memoryInfoCollector = MemoryInfoCollector()

    public init() {}

    public func getFingerprint() -> [DeviceInfoEntry] {
        let memoryInfo = memoryInfoCollector.collect()
        return [
            memoryInfo.device_memory
        ]
    }
}
