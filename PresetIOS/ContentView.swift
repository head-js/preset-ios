import SwiftUI

struct ContentView: View {

    @State private var connectivityHelper = ConnectivityHelperBox()
    @State private var deviceInfoHelper = DeviceInfoHelperBox()
    @State private var packageInfoHelper = PackageInfoHelperBox()
    @State private var webViewHelper = WebViewHelperBox()

    @State private var statusText: String = "checking..."
    @State private var deviceInfo: DeviceInfo = DeviceInfo(idfa: "unknown", idfv: "unknown")
    @State private var appPackageInfo: AppPackageInfo = AppPackageInfo(
        appName: "unknown", bundleId: "unknown", versionName: "unknown", versionCode: "unknown"
    )

    var body: some View {
        VStack(spacing: 0) {
            infoList
                .frame(height: 340)

            Divider()

            WebView(helper: webViewHelper.helper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            updateStatus()
            updateDeviceInfo()
            updateAppPackageInfo()
            webViewHelper.helper.loadUrl("https://www.apple.com")
            connectivityHelper.helper.registerCallback { _ in
                updateStatus()
            }
        }
        .onDisappear {
            connectivityHelper.helper.unregisterCallback()
        }
    }
    private var infoList: some View {
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
        }
        .listStyle(GroupedListStyle())
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

final class WebViewHelperBox {
    let helper = WebViewHelper()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
