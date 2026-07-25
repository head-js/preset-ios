import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

public struct DeviceInfo {
    public let idfa: String
    public let idfv: String

    public init(idfa: String, idfv: String) {
        self.idfa = idfa
        self.idfv = idfv
    }
}

public class DeviceInfoHelper {

    public private(set) var currentInfo: DeviceInfo = DeviceInfo(
        idfa: "unknown",
        idfv: "unknown"
    )

    public init() {}

    public func getCurrentDeviceInfo() -> DeviceInfo {
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        currentInfo = DeviceInfo(idfa: idfa, idfv: idfv)
        return currentInfo
    }

    public func getDisplayString() -> String {
        let info = getCurrentDeviceInfo()
        return "IDFA: \(info.idfa) | IDFV: \(info.idfv)"
    }
}
