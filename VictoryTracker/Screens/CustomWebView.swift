import SwiftUI
import WebKit
import UIKit

final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool

    var webViewStack: [WKWebView] = []

    init(canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
        _canGoBack = canGoBack
        _canGoForward = canGoForward
    }

    func updateNavigationButtons(for webView: WKWebView) {
        canGoBack = webView.canGoBack || webViewStack.count > 1
        canGoForward = webView.canGoForward
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationButtons(for: webView)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel); return
        }

        let scheme = (url.scheme ?? "").lowercased()
        let internalSchemes: Set<String> = ["http", "https", "about", "srcdoc", "blob", "data", "javascript", "file"]

        if internalSchemes.contains(scheme) {
            decisionHandler(.allow)
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void)
    {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        webView.window?.rootViewController?.present(ac, animated: true)
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView?
    {
        let isRealPopup =
            (windowFeatures.width?.intValue ?? 0) > 0 ||
            (windowFeatures.height?.intValue ?? 0) > 0 ||
            (navigationAction.request.url?.absoluteString.contains("popup") == true)

        let lower = navigationAction.request.url?.absoluteString.lowercased() ?? ""
        let isSyntheticBlank = lower.isEmpty ||
                               lower == "about:blank" ||
                               lower == "about:srcdoc" ||
                               lower.hasPrefix("data:") ||
                               lower.hasPrefix("blob:")

        if !isRealPopup && isSyntheticBlank {
            return nil
        }

        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true

        webView.addSubview(popup)
        webView.bringSubviewToFront(popup)

        webViewStack.append(popup)
        updateNavigationButtons(for: popup)
        return popup
    }

    func closeTopWebView() {
        guard webViewStack.count > 1 else { return }
        let top = webViewStack.removeLast()
        top.removeFromSuperview()
        if let visible = webViewStack.last {
            updateNavigationButtons(for: visible)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let customUserAgent: String?

    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var webView: WKWebView?

    var externalCoordinator: WebViewCoordinator?

    func makeCoordinator() -> WebViewCoordinator {
        externalCoordinator ?? WebViewCoordinator(canGoBack: $canGoBack, canGoForward: $canGoForward)
    }

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = true

        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.allowsInlineMediaPlayback = true
        cfg.preferences = prefs
        cfg.applicationNameForUserAgent = "Version/17.2 Mobile/15E148 Safari/604.1"

        let wk = WKWebView(frame: .zero, configuration: cfg)
        wk.allowsBackForwardNavigationGestures = true
        wk.scrollView.delegate = context.coordinator
        wk.navigationDelegate = context.coordinator
        wk.uiDelegate = context.coordinator
        if let ua = customUserAgent { wk.customUserAgent = ua }

        wk.load(URLRequest(url: url))

        context.coordinator.webViewStack = [wk]
        DispatchQueue.main.async { webView = wk }
        return wk
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

struct CustomWebView: View {
    let main_link: String
    var customUserAgent: String? = nil

    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var innerWebView: WKWebView?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if let url = URL(string: main_link) {
                    WebViewRepresentable(
                        url: url,
                        customUserAgent: customUserAgent,
                        canGoBack: $canGoBack,
                        canGoForward: $canGoForward,
                        webView: $innerWebView
                    )
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    Text("URL")
                        .foregroundColor(.white)
                        .padding(.top, 40)
                }

                HStack {
                    Button {
                        if let coord = (innerWebView?.navigationDelegate as? WebViewCoordinator),
                           let top = coord.webViewStack.last {
                            if top.canGoBack {
                                top.goBack()
                            } else if coord.webViewStack.count > 1 {
                                coord.closeTopWebView()
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(canGoBack ? .white : .gray)
                            .imageScale(.large)
                    }
                    .disabled(!canGoBack)
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Spacer()

                    Button {
                        if let coord = (innerWebView?.navigationDelegate as? WebViewCoordinator) {
                            coord.webViewStack.last?.goForward()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(canGoForward ? .white : .gray)
                            .imageScale(.large)
                    }
                    .disabled(!canGoForward)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .frame(height: 20)
                .background(Color.black)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
