import SwiftUI
import WebKit

struct YoutubeEmbedView: UXViewRepresentable {
	let id: String?

	init(url: URL) {
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		if let v = components?.queryItems?.first(where: { $0.name == "v" })?.value {
			id = v
		} else if let lastComponent = url.pathComponents.last, lastComponent.count == 11 {
			id = lastComponent
		} else {
			id = nil
		}
	}

	#if os(macOS)
	func makeNSView(context: Context) -> WKWebView { makeView(context: context) }
	func updateNSView(_ view: WKWebView, context: Context) {}
	#else
	func makeUIView(context: Context) -> WKWebView { makeView(context: context) }
	func updateUIView(_ view: WKWebView, context: Context) {}
	#endif

	private func makeView(context: Context) -> WKWebView {
		let configuration = WKWebViewConfiguration()
		let view = WKWebView(frame: .zero, configuration: configuration)
		#if os(iOS)
		configuration.allowsInlineMediaPlayback = true
		view.isOpaque = false
		#endif
		if let id = id {
			view.loadHTMLString(#"<iframe width="100%" height="100%" type="text/html" src="https://www.youtube-nocookie.com/embed/\#(id)?autoplay=1" frameborder="0"></iframe><style>body{margin:0;}</style>"#, baseURL: nil)
		}
		return view
	}
}
