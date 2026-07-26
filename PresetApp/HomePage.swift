import SwiftUI
import PresetDeviceInfo

struct HomePage: View {
    let dependencies: MainStageDependencies

    @State private var statusText: String = "checking..."
    @State private var identityInfo: [DeviceInfoEntry] = []
    @State private var fingerprintInfo: [DeviceInfoEntry] = []
    @State private var appInfo: [DeviceInfoEntry] = []
    @State private var httpLoading: Bool = false
    @State private var httpResult: String = "—"

    var body: some View {
        List {
            Section(header: Text("Network")) {
                Text(statusText)
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section(header: Text("App")) {
                ForEach(appInfo, id: \.key) { entry in
                    row(entry.label, entry.value)
                }
            }

            Section(header: Text("Identity")) {
                ForEach(identityInfo, id: \.key) { entry in
                    row(entry.label, entry.value)
                }
            }

            Section(header: Text("Fingerprint")) {
                ForEach(fingerprintInfo, id: \.key) { entry in
                    row(entry.label, entry.value)
                }
            }

            Section(header: Text("HTTP")) {
                Button(action: sendHttpPost) {
                    Text(httpLoading ? "Sending..." : "Send POST")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(httpLoading)
                row("Result", httpResult)
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear {
            updateStatus()
            updateIdentityInfo()
            updateFingerprintInfo()
            updateAppInfo()
            dependencies.connectivityHelper.helper.registerCallback { _ in
                updateStatus()
            }
        }
        .onDisappear {
            dependencies.connectivityHelper.helper.unregisterCallback()
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
        statusText = dependencies.connectivityHelper.helper.getCurrentConnectivity().label
    }

    private func updateIdentityInfo() {
        identityInfo = dependencies.deviceIdentityRepository.getIdentity()
    }

    private func updateFingerprintInfo() {
        fingerprintInfo = dependencies.deviceInfoRepository.getFingerprint()
    }

    private func updateAppInfo() {
        appInfo = dependencies.appInfoRepository.getAppInfo()
    }

    private func sendHttpPost() {
        guard !httpLoading else { return }
        httpLoading = true
        httpResult = "sending..."
        APIClient.shared.postTest(body: ["foo": "bar", "platform": "ios"]) { result in
            httpLoading = false
            switch result {
            case .success(let response):
                httpResult = response.url ?? "OK"
            case .failure(let error):
                httpResult = "ERR: \(error.localizedDescription)"
            }
        }
    }
}
