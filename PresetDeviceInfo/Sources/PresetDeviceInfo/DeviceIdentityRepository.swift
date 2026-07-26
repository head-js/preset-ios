import AppTrackingTransparency

public final class DeviceIdentityRepository {
    private let identityInfoCollector = IdentityInfoCollector()

    public init() {}

    public func getIdentity() -> [DeviceInfoEntry] {
        let identityInfo = identityInfoCollector.collect()
        return [
            identityInfo.idfa,
            identityInfo.idfv
        ]
    }

    /**
     * ATT 授权决定是否允许跨应用追踪，本质上属于业务隐私与用户同意流程，并不是设备信息采集行为。
     * 当前暂时由标识 Repository 提供统一入口，便于宿主应用在授权完成后重新读取 IDFA；如果业务方已有
     * 隐私弹窗、CMP 或完整的授权编排，应由业务层直接管理 ATT，并移除该入口。
     *
     * - 宿主应用必须在 Info.plist 中声明 `NSUserTrackingUsageDescription`，否则请求授权可能导致应用崩溃。
     * - 应在应用进入 active 状态且已有可见界面后调用，避免启动阶段弹窗失败或与其他系统弹窗冲突。
     * - 系统授权框通常只展示一次；用户已经选择后，再次调用只会返回现有状态。
     * - 授权完成后需要再次调用 `getIdentity()`，已经取得的数组不会自动刷新。
     */
    public func requestTrackingAuthorization(
        completion: @escaping (ATTrackingManager.AuthorizationStatus) -> Void
    ) {
        ATTrackingManager.requestTrackingAuthorization(completionHandler: completion)
    }
}
