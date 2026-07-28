import SwiftUI

final class WebViewPage: UIHostingController<WebViewPage.View> {
    final class State {
        let helper = WebViewHelper()
        var hasLoadedInitialURL = false
    }

    init() {
        super.init(rootView: View(state: State()))
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WebViewPage {
    struct View: SwiftUI.View {
        let state: State

        var body: some SwiftUI.View {
            WebView(helper: state.helper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    if !state.hasLoadedInitialURL {
                        state.helper.loadUrl("https://www.apple.com")
                        state.hasLoadedInitialURL = true
                    }
                }
        }
    }
}
