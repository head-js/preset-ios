import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

struct DeviceInfo {
    let idfa: String
    let idfv: String
}

class DeviceInfoHelper {

    private(set) var currentInfo: DeviceInfo = DeviceInfo(
        idfa: "unknown",
        idfv: "unknown"
    )

    func getCurrentDeviceInfo() -> DeviceInfo {
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        currentInfo = DeviceInfo(idfa: idfa, idfv: idfv)
        return currentInfo
    }

    func getDisplayString() -> String {
        let info = getCurrentDeviceInfo()
        return "IDFA: \(info.idfa) | IDFV: \(info.idfv)"
    }
}
