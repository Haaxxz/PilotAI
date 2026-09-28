import SwiftUI
import WebKit

public struct BrowserView: View {
    @State private var urlString: String = "https://google.com"
    @State private var currentURL: URL? = URL(string: "https://google.com")
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = false
    @State private var title: String = ""
    @State private var webView = WKWebView()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Address bar
            HStack(spacing: 8) {
                Button(action: { webView.goBack() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(canGoBack ? .blue : .secondary)
                }
                .disabled(!canGoBack)

                Button(action: { webView.goForward() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canGoForward ? .blue : .secondary)
                }
                .disabled(!canGoForward)

                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("Search or enter URL", text: $urlString, onCommit: loadURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .font(.system(size: 14))
                    if !urlString.isEmpty {
                        Button(action: { urlString = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                Button(action: {
                    if isLoading {
                        webView.stopLoading()
                    } else {
                        webView.reload()
                    }
                }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            if isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(height: 2)
            }

            // Webview
            WebViewRepresentable(
                webView: webView,
                url: $currentURL,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                title: $title,
                urlString: $urlString
            )
        }
        .navigationTitle(title.isEmpty ? "Agent Browser" : title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadURL() {
        var str = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.isEmpty { return }
        if !str.lowercased().hasPrefix("http://") && !str.lowercased().hasPrefix("https://") {
            if str.contains(".") && !str.contains(" ") {
                str = "https://" + str
            } else {
                let encoded = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str
                str = "https://www.google.com/search?q=\(encoded)"
            }
        }
        if let u = URL(string: str) {
            currentURL = u
            webView.load(URLRequest(url: u))
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    @Binding var url: URL?
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var title: String
    @Binding var urlString: String

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        if let u = url {
            webView.load(URLRequest(url: u))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            parent.title = webView.title ?? ""
            if let u = webView.url?.absoluteString {
                parent.urlString = u
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
