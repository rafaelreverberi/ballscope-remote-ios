import Foundation
import WebKit
import Combine

final class JetsonWebRouter: NSObject, ObservableObject {
    @Published private(set) var currentPath: String = "/"

    var onPathChange: ((String) -> Void)?
    var onFullscreenChange: ((Bool) -> Void)?
    var onFullscreenToggleRequest: (() -> Void)?
    var onNativeStreamFullscreenRequest: ((URL, String?, Bool) -> Void)?

    let webView: WKWebView
    private var settings: AppSettings = .default

    override init() {
        let userContentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        super.init()

        Self.configureUserScripts(on: userContentController)
        userContentController.add(self, name: "ballscopeFullscreen")
        userContentController.add(self, name: "ballscopeFullscreenToggleRequest")
        userContentController.add(self, name: "ballscopeNativeStreamFullscreen")
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
              try {
                if (window.__ballscopeSetAppFullscreen) { window.__ballscopeSetAppFullscreen(true); }
              } catch (e) {}
              var liveStage = document.getElementById('liveStage');
              if (liveStage) { return; } // App-only fullscreen fallback for BallScope live image stream
              var el = document.documentElement;
              if (document.fullscreenElement) { return; }
              if (el.requestFullscreen) { el.requestFullscreen(); }
              else if (el.webkitRequestFullscreen) { el.webkitRequestFullscreen(); }
            })();
            """
        } else {
            js = """
            (function() {
              try {
                if (document.exitPictureInPicture && document.pictureInPictureElement) {
                  document.exitPictureInPicture();
                }
              } catch (e) {}
              var videos = document.querySelectorAll('video');
              videos.forEach(function(v) {
                try {
                  if (v.webkitSetPresentationMode) {
                    v.webkitSetPresentationMode('inline');
                  }
                } catch (e) {}
              });
              try {
                if (window.__ballscopeSetAppFullscreen) { window.__ballscopeSetAppFullscreen(false); }
              } catch (e) {}
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

            var fullscreenStyleId = 'ballscope-ios-live-fullscreen-fallback';
            if (!document.getElementById(fullscreenStyleId)) {
                var fullscreenStyle = document.createElement('style');
                fullscreenStyle.id = fullscreenStyleId;
                fullscreenStyle.innerHTML =
                  'html.ballscope-app-fs, body.ballscope-app-fs { overflow:hidden !important; background:#000 !important; height:100% !important; }' +
                  '#liveStage.ballscope-app-force-fullscreen { position:fixed !important; inset:0 !important; width:100vw !important; height:100dvh !important; z-index:2147483646 !important; margin:0 !important; padding:0 !important; border-radius:0 !important; border:none !important; background:#000 !important; }' +
                  '#liveStage.ballscope-app-force-fullscreen .frame { width:100% !important; height:100% !important; border:none !important; border-radius:0 !important; background:#000 !important; }' +
                  '#liveStage.ballscope-app-force-fullscreen .frame.main { aspect-ratio:auto !important; min-height:100dvh !important; }' +
                  '#liveStage.ballscope-app-force-fullscreen img#liveMainImg { width:100% !important; height:100% !important; max-width:none !important; max-height:none !important; object-fit:contain !important; background:#000 !important; }' +
                  '#liveStage.ballscope-app-force-fullscreen .label-chip { z-index:2147483647 !important; }';
                head.appendChild(fullscreenStyle);
            }

            window.__ballscopeSetAppFullscreen = function(active) {
                try {
                    document.documentElement.classList.toggle('ballscope-app-fs', !!active);
                    if (document.body) document.body.classList.toggle('ballscope-app-fs', !!active);
                    var stage = document.getElementById('liveStage');
                    if (stage) stage.classList.toggle('ballscope-app-force-fullscreen', !!active);
                } catch (e) {}
            };

            var lastFullscreenState = null;

            function computeFullscreenState() {
                var domFullscreen = !!(document.fullscreenElement || document.webkitFullscreenElement);
                var pipActive = !!document.pictureInPictureElement;
                var appForced = !!(document.documentElement && document.documentElement.classList && document.documentElement.classList.contains('ballscope-app-fs'));
                var webkitVideoPresentation = false;
                try {
                    var videos = document.querySelectorAll('video');
                    for (var i = 0; i < videos.length; i++) {
                        var v = videos[i];
                        if (v.webkitDisplayingFullscreen) {
                            webkitVideoPresentation = true;
                            break;
                        }
                        if (v.webkitPresentationMode && v.webkitPresentationMode !== 'inline') {
                            webkitVideoPresentation = true;
                            break;
                        }
                    }
                } catch (e) {}
                return domFullscreen || pipActive || webkitVideoPresentation || appForced;
            }

            function publishFullscreen() {
                try {
                    var active = computeFullscreenState();
                    if (lastFullscreenState === active) { return; }
                    lastFullscreenState = active;
                    window.webkit.messageHandlers.ballscopeFullscreen.postMessage({ active: active });
                } catch (e) {}
            }

            function requestAppFullscreenToggle(ev) {
                try {
                    if (ev) {
                        if (ev.preventDefault) ev.preventDefault();
                        if (ev.stopImmediatePropagation) ev.stopImmediatePropagation();
                        if (ev.stopPropagation) ev.stopPropagation();
                    }
                    window.webkit.messageHandlers.ballscopeFullscreenToggleRequest.postMessage({});
                } catch (e) {}
                return false;
            }

            function requestNativeStreamFullscreen(ev) {
                try {
                    if (ev) {
                        if (ev.preventDefault) ev.preventDefault();
                        if (ev.stopImmediatePropagation) ev.stopImmediatePropagation();
                        if (ev.stopPropagation) ev.stopPropagation();
                    }
                    var img = document.getElementById('liveMainImg');
                    if (!img || !img.src) {
                        return requestAppFullscreenToggle(ev);
                    }
                    var label = '';
                    var labelEl = document.getElementById('previewLabel');
                    if (labelEl && labelEl.textContent) label = labelEl.textContent;
                    var fit = !!(img.classList && img.classList.contains('fit'));
                    window.webkit.messageHandlers.ballscopeNativeStreamFullscreen.postMessage({
                        src: img.src,
                        label: label,
                        fit: fit
                    });
                } catch (e) {
                    return requestAppFullscreenToggle(ev);
                }
                return false;
            }

            function patchLiveFullscreenButton() {
                try {
                    var btn = document.getElementById('fsBtn');
                    if (!btn) { return; }
                    if (btn.__ballscopeFsPatched) { return; }
                    btn.__ballscopeFsPatched = true;

                    // Replace page handler so WKWebView doesn't run the site's requestFullscreen path.
                    btn.onclick = requestNativeStreamFullscreen;
                    btn.addEventListener('click', requestNativeStreamFullscreen, true);
                } catch (e) {}
            }

            document.addEventListener('fullscreenchange', publishFullscreen);
            document.addEventListener('webkitfullscreenchange', publishFullscreen);
            document.addEventListener('enterpictureinpicture', publishFullscreen, true);
            document.addEventListener('leavepictureinpicture', publishFullscreen, true);
            document.addEventListener('webkitbeginfullscreen', publishFullscreen, true);
            document.addEventListener('webkitendfullscreen', publishFullscreen, true);
            document.addEventListener('click', function(ev) {
                try {
                    var target = ev.target;
                    var btn = target && target.closest ? target.closest('#fsBtn') : null;
                    if (!btn) { return; }
                    requestNativeStreamFullscreen(ev);
                } catch (e) {}
            }, true);
            window.addEventListener('pageshow', publishFullscreen);
            document.addEventListener('visibilitychange', publishFullscreen);
            patchLiveFullscreenButton();
            setTimeout(publishFullscreen, 0);
            setTimeout(patchLiveFullscreenButton, 0);
            setTimeout(patchLiveFullscreenButton, 300);
            setInterval(publishFullscreen, 600);
            setInterval(patchLiveFullscreenButton, 1000);
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
        if message.name == "ballscopeFullscreen" {
            if let dict = message.body as? [String: Any],
               let active = dict["active"] as? Bool {
                onFullscreenChange?(active)
            }
            return
        }

        if message.name == "ballscopeFullscreenToggleRequest" {
            onFullscreenToggleRequest?()
            return
        }

        if message.name == "ballscopeNativeStreamFullscreen" {
            guard let dict = message.body as? [String: Any],
                  let src = dict["src"] as? String,
                  let url = resolvedMessageURL(from: src)
            else { return }

            let label = dict["label"] as? String
            let fit = (dict["fit"] as? Bool) ?? true
            onNativeStreamFullscreenRequest?(url, label, fit)
        }
    }

    private func resolvedMessageURL(from src: String) -> URL? {
        if let absolute = URL(string: src), absolute.scheme != nil {
            return absolute
        }
        if let base = webView.url {
            return URL(string: src, relativeTo: base)?.absoluteURL
        }
        return nil
    }
}
