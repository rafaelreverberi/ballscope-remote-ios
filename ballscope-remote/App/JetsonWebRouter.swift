import Foundation
import WebKit
import Combine

final class JetsonWebRouter: NSObject, ObservableObject {
    @Published private(set) var currentPath: String = "/"

    var onPathChange: ((String) -> Void)?
    var onFullscreenChange: ((Bool) -> Void)?

    let webView: WKWebView
    private var settings: AppSettings = .default

    override init() {
        let userContentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.allowsInlineMediaPlayback = true
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        super.init()

        Self.configureUserScripts(on: userContentController)
        userContentController.add(self, name: "ballscopeFullscreen")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.bouncesZoom = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
    }

    func navigate(to destination: AppDestination, force: Bool = false) {
        let path = destination.webPath ?? "/"
        guard let url = resolvedURL(path: path) else { return }

        let currentURL = webView.url
        if !force,
           currentURL?.host == url.host,
           currentURL?.port == url.port,
           normalizedPath(currentURL?.path) == normalizedPath(url.path) {
            return
        }

        webView.load(URLRequest(url: url))
    }

    func reloadOrNavigate(to destination: AppDestination) {
        if let currentURL = webView.url,
           currentURL.host == settings.baseURL.host,
           currentURL.port == settings.baseURL.port {
            webView.reload()
            return
        }

        navigate(to: destination, force: true)
    }

    func setDocumentFullscreen(_ enabled: Bool) {
        let js: String
        if enabled {
            js = """
            (function() {
              var el = document.documentElement;
              if (document.fullscreenElement) { return; }
              if (el.requestFullscreen) { el.requestFullscreen(); }
              else if (el.webkitRequestFullscreen) { el.webkitRequestFullscreen(); }
            })();
            """
        } else {
            js = """
            (function() {
              if (document.exitFullscreen && document.fullscreenElement) { document.exitFullscreen(); return; }
              if (document.webkitExitFullscreen) { document.webkitExitFullscreen(); }
            })();
            """
        }
        webView.evaluateJavaScript(js)
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

    private static func configureUserScripts(on controller: WKUserContentController) {
        let source = """
        (function() {
            var head = document.head || document.getElementsByTagName('head')[0];
            if (!head) { return; }

            var viewport = document.querySelector('meta[name=\"viewport\"]');
            if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                head.appendChild(viewport);
            }
            viewport.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';

            var styleId = 'ballscope-ios-input-font-fix';
            if (!document.getElementById(styleId)) {
                var style = document.createElement('style');
                style.id = styleId;
                style.innerHTML = 'input, textarea, select { font-size: 16px !important; }';
                head.appendChild(style);
            }

            function publishFullscreen() {
                try {
                    var active = !!(document.fullscreenElement || document.webkitFullscreenElement);
                    window.webkit.messageHandlers.ballscopeFullscreen.postMessage({ active: active });
                } catch (e) {}
            }

            document.addEventListener('fullscreenchange', publishFullscreen);
            document.addEventListener('webkitfullscreenchange', publishFullscreen);
            window.addEventListener('pageshow', publishFullscreen);
            setTimeout(publishFullscreen, 0);
        })();
        """

        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        controller.addUserScript(userScript)
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

extension JetsonWebRouter: WKUIDelegate {}

extension JetsonWebRouter: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "ballscopeFullscreen" else { return }
        if let dict = message.body as? [String: Any],
           let active = dict["active"] as? Bool {
            onFullscreenChange?(active)
        }
    }
}
