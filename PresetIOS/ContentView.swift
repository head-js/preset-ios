import SwiftUI

struct ContentView: View {

    @State private var connectivityHelper = ConnectivityHelperBox()
    @State private var deviceInfoHelper = DeviceInfoHelperBox()
    @State private var packageInfoHelper = PackageInfoHelperBox()
    @State private var statusText: String = "checking..."
    @State private var deviceInfo: DeviceInfo = DeviceInfo(idfa: "unknown", idfv: "unknown")
    @State private var appPackageInfo: AppPackageInfo = AppPackageInfo(
        appName: "unknown", bundleId: "unknown", versionName: "unknown", versionCode: "unknown"
    )
    @State private var logs: [String] = []

    var body: some View {
        List {
            Section(header: Text("Network")) {
                Text(statusText)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section(header: Text("App")) {
                row("Name", appPackageInfo.appName)
                row("Bundle ID", appPackageInfo.bundleId)
                row("Version", appPackageInfo.versionName)
                row("Build", appPackageInfo.versionCode)
            }

            Section(header: Text("Device")) {
                row("IDFA", deviceInfo.idfa)
                row("IDFV", deviceInfo.idfv)
            }

            Section(header: Text("Log")) {
                ForEach(logs.indices, id: \.self) { index in
                    Text(logs[index])
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear {
            updateStatus()
            updateDeviceInfo()
            updateAppPackageInfo()
            connectivityHelper.helper.registerCallback { type in
                appendLog("Network changed: \(type.label)")
                updateStatus()
            }
        }
        .onDisappear {
            connectivityHelper.helper.unregisterCallback()
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func updateStatus() {
        statusText = connectivityHelper.helper.getCurrentConnectivity().label
    }

    private func updateDeviceInfo() {
        deviceInfo = deviceInfoHelper.helper.getCurrentDeviceInfo()
    }

    private func updateAppPackageInfo() {
        appPackageInfo = packageInfoHelper.helper.getCurrentAppPackageInfo()
    }

    private func appendLog(_ message: String) {
        logs.insert(message, at: 0)
    }
}

final class ConnectivityHelperBox {
    let helper = ConnectivityHelper()
}

final class DeviceInfoHelperBox {
    let helper = DeviceInfoHelper()
}

final class PackageInfoHelperBox {
    let helper = PackageInfoHelper()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
