import AdSupport
import AppTrackingTransparency
import UIKit

/**
 * Apple 设备标识读取结果。各字段的声明、授权弹窗、生命周期和隐私要求详见对应读取方法。
 *
 * 标识来源体系：
 * - IDFA 来自 AdSupport，面向广告投放、跨应用广告归因等用途；iOS 14+ 受 ATT 授权状态控制。
 * - IDFV 来自 UIKit，只能在同一 Vendor 的应用范围内关联设备，与 IDFA 的广告标识体系无关。
 *
 * 业界使用习惯：
 * - 广告投放和跨应用归因应在 ATT 授权后使用 IDFA；用户拒绝后，不应改用 IDFV、服务端账号或其他持久标识
 *   重新建立同等的跨应用追踪能力。
 * - IDFV 更适合开发者自有应用内的非广告统计、风控或状态关联。它不是永久硬件号，也不适合作为用户账号主键。
 * - IDFA 和 IDFV 都可用于跨 session 关联，应按个人信息处理，并在隐私政策、App Store 隐私标签和数据用途声明中
 *   根据实际业务用途进行披露。
 */
struct IdentityInfo: Equatable {
    /** IDFA（Identifier for Advertisers），Apple 广告标识符。 */
    let idfa: DeviceInfoEntry

    /** IDFV（Identifier for Vendor），同一 Vendor 范围内的设备标识符。 */
    let idfv: DeviceInfoEntry

    init(idfa: DeviceInfoEntry, idfv: DeviceInfoEntry) {
        self.idfa = idfa
        self.idfv = idfv
    }
}

/**
 * `collect()` 只读取当前可用值，不会主动弹出 ATT 授权框。
 * ATT 授权不属于采集行为；需要 IDFA 时，应先由 Repository 或业务层完成授权流程，再重新采集。
 */
final class IdentityInfoCollector {
    func collect() -> IdentityInfo {
        IdentityInfo(
            idfa: DeviceInfoEntry(key: "idfa", value: readIdfa(), label: "IDFA"),
            idfv: DeviceInfoEntry(key: "idfv", value: readIdfv(), label: "IDFV")
        )
    }

    /**
     * IDFA（Identifier for Advertisers），通过 `ASIdentifierManager` 获取。
     *
     * - 生命周期：系统管理的设备级广告标识，可能在系统重置或 Apple 定义的其他重置场景后变化，不能作为永久主键。
     * - Info.plist 声明：读取 API 本身不需要权限声明；请求 ATT 时必须声明 `NSUserTrackingUsageDescription`。
     * - 用户授权弹窗：本方法不触发弹窗。ATT 授权应在 Repository 或业务层显式发起。
     * - 返回值：仅在 ATT 状态为 `.authorized` 时返回 UUID；未决定、拒绝、受限制或系统返回全零 UUID 时返回空字符串。
     * - PII：是。可用于跨应用广告追踪和归因，需要结合实际用途完成隐私政策、ATT 和 App Store 隐私披露。
     * - 实际使用：模拟器通常无法提供可用于真实归因的 IDFA；调用方必须接受空值，不能使用 IDFV 绕过 ATT 选择。
     */
    private func readIdfa() -> String {
        guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
            return ""
        }

        let identifier = ASIdentifierManager.shared().advertisingIdentifier
        guard identifier != Self.zeroIdentifier else {
            return ""
        }
        return identifier.uuidString
    }

    /**
     * IDFV（Identifier for Vendor），通过 `UIDevice.identifierForVendor` 获取。
     *
     * - 生命周期：在同一设备、同一 Vendor 的应用范围内通常保持稳定；设备上该 Vendor 的所有应用都被卸载后，
     *   后续重新安装时标识可能变化，因此不能作为永久设备号或账号主键。
     * - Info.plist 声明：不需要。
     * - 用户授权弹窗：不触发，无运行时权限和 ATT 弹窗。
     * - 返回值：正常时返回 UUID；系统暂时无法提供时返回空字符串，调用方必须允许该字段为空。
     * - PII：是。可用于同一 Vendor 范围内跨 session、跨应用关联，需要按实际用途进行隐私披露。
     * - 实际使用：适合自有应用统计、诊断或风控关联，不适合跨 Vendor 广告归因，也不应被用来规避用户拒绝 ATT 的选择。
     */
    private func readIdfv() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    private static let zeroIdentifier = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}
