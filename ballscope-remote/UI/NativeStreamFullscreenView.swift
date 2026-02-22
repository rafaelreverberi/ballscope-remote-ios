import SwiftUI
import WebKit

struct NativeStreamFullscreenView: View {
    let session: AppModel.NativeStreamFullscreenSession
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let safe = proxy.safeAreaInsets
            let isLandscape = proxy.size.width > proxy.size.height
            let topChromeHeight: CGFloat = isLandscape ? 54 : 62
            let topReserved = isLandscape
                ? (safe.top + 8)   // keep stream closer to edges in landscape; chrome overlays above it
                : (safe.top + topChromeHeight + 8)
            let bottomReserved = isLandscape
                ? (max(safe.bottom, 8) + 4)
                : (max(safe.bottom, 12) + 8)
            let sideReserved = max(safe.leading, safe.trailing) + (isLandscape ? 6 : 12)

            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                // Soft spotlight so the centered stream feels more like a native media surface.
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.white.opacity(0.015),
                        .clear
                    ],
                    center: .center,
                    startRadius: 60,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.7
                )
                .ignoresSafeArea()

                NativeImageStreamWebView(
                    url: session.url,
                    fitContain: session.fitContain,
                    contentInsets: .init(top: topReserved, left: sideReserved, bottom: bottomReserved, right: sideReserved)
                )
                .ignoresSafeArea()

                topChrome(title: session.title)
                    .padding(.top, safe.top + 8)
                    .padding(.horizontal, 12)
            }
        }
    }

    @ViewBuilder
    private func topChrome(title: String?) -> some View {
        HStack(spacing: 10) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            } else {
                Text("Live Stream")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct NativeImageStreamWebView: UIViewRepresentable {
    let url: URL
    let fitContain: Bool
    let contentInsets: UIEdgeInsets

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        load(into: webView, coordinator: context.coordinator)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastURL != url ||
            context.coordinator.lastFitContain != fitContain ||
            context.coordinator.lastInsets != contentInsets {
            load(into: webView, coordinator: context.coordinator)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastURL: URL?
        var lastFitContain = true
        var lastInsets: UIEdgeInsets = .zero
    }

    private func load(into webView: WKWebView, coordinator: Coordinator) {
        let escaped = url.absoluteString
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let objectFit = fitContain ? "contain" : "cover"
        let topInset = Int(contentInsets.top.rounded())
        let leftInset = Int(contentInsets.left.rounded())
        let bottomInset = Int(contentInsets.bottom.rounded())
        let rightInset = Int(contentInsets.right.rounded())
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
          <style>
            html, body {
              margin: 0;
              width: 100%;
              height: 100%;
              overflow: hidden;
              background: #000;
            }
            .wrap {
              position: fixed;
              inset: \(topInset)px \(rightInset)px \(bottomInset)px \(leftInset)px;
              display: flex;
              align-items: center;
              justify-content: center;
              background: #000;
            }
            img {
              max-width: 100%;
              max-height: 100%;
              width: auto;
              height: auto;
              object-fit: \(objectFit);
              background: #000;
              user-select: none;
              -webkit-user-drag: none;
            }
          </style>
        </head>
        <body>
          <div class="wrap">
            <img src="\(escaped)" alt="BallScope Live Stream" />
          </div>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
        coordinator.lastURL = url
        coordinator.lastFitContain = fitContain
        coordinator.lastInsets = contentInsets
    }
}
