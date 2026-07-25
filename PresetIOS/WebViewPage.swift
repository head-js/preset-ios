import SwiftUI

struct WebViewPage: View {
    let helperBox: WebViewHelperBox

    var body: some View {
        WebView(helper: helperBox.helper)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if !helperBox.hasLoadedInitialURL {
                    helperBox.helper.loadUrl("https://www.apple.com")
                    helperBox.hasLoadedInitialURL = true
                }
            }
    }
}
