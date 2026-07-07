import SwiftUI

struct ContentView: View {

    @State private var connectivityHelper = ConnectivityHelperBox()
    @State private var statusText: String = "Network: checking..."
    @State private var logs: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            Text(statusText)
                .font(.system(size: 24, weight: .medium))
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(logs.indices, id: \.self) { index in
                        Text(logs[index])
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            updateStatus()
            connectivityHelper.helper.registerCallback { type in
                appendLog("Network changed: \(type.label)")
                updateStatus()
            }
        }
        .onDisappear {
            connectivityHelper.helper.unregisterCallback()
        }
    }

    private func updateStatus() {
        statusText = "Network: \(connectivityHelper.helper.getCurrentConnectivity().label)"
    }

    private func appendLog(_ message: String) {
        logs.insert(message, at: 0)
    }
}

final class ConnectivityHelperBox {
    let helper = ConnectivityHelper()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
