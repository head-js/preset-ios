import SwiftUI
import WebKit

class WebViewHelper: NSObject, WKNavigationDelegate {

    let webView: WKWebView

    var onPageStarted: ((URL?) -> Void)?
    var onPageFinished: ((URL?) -> Void)?
    var onPageError: ((Error) -> Void)?

    override init() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.bounces = true
    }

    func loadUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }

    func canGoBack() -> Bool {
        return webView.canGoBack
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        DispatchQueue.main.async { self.onPageStarted?(webView.url) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        DispatchQueue.main.async { self.onPageFinished?(webView.url) }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        DispatchQueue.main.async { self.onPageError?(error) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        DispatchQueue.main.async { self.onPageError?(error) }
    }
}

struct WebView: UIViewRepresentable {
    let helper: WebViewHelper

    func makeUIView(context: Context) -> WKWebView {
        return helper.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}
