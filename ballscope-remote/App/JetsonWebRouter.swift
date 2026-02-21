import Foundation
import WebKit
import Combine

final class JetsonWebRouter: NSObject, ObservableObject {
    @Published private(set) var currentPath: String = "/"

    var onPathChange: ((String) -> Void)?

    let webView: WKWebView
    private var settings: AppSettings = .default

    override init() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        super.init()

        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
    }

    func navigate(to destination: AppDestination) {
        let path = destination.webPath ?? "/"
        guard let url = resolvedURL(path: path) else { return }

        let currentURL = webView.url
        if currentURL?.host == url.host,
           currentURL?.port == url.port,
           normalizedPath(currentURL?.path) == normalizedPath(url.path) {
            return
        }

        webView.load(URLRequest(url: url))
    }

    private func resolvedURL(path: String) -> URL? {
        var components = URLComponents(url: settings.baseURL, resolvingAgainstBaseURL: false)
        components?.path = normalizedPath(path)
        return components?.url
    }

    private func normalizedPath(_ path: String?) -> String {
        guard let path else { return "/" }
        if path.isEmpty { return "/" }
        return path.hasPrefix("/") ? path : "/\(path)"
    }

    private func publishPath(from url: URL?) {
        let path = normalizedPath(url?.path)
        if path != currentPath {
            currentPath = path
            onPathChange?(path)
        }
    }
}

extension JetsonWebRouter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        publishPath(from: webView.url)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        publishPath(from: navigationAction.request.url)
        decisionHandler(.allow)
    }
}
