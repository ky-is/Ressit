import SwiftUI
import WebKit

struct YoutubeEmbedView: UIViewRepresentable {
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

	func makeUIView(context: Context) -> WKWebView {
		let configuration = WKWebViewConfiguration()
		configuration.allowsInlineMediaPlayback = true
		let view = WKWebView(frame: .zero, configuration: configuration)
		view.isOpaque = false
		if let id = id {
			view.loadHTMLString(#"<iframe width="100%" height="100%" type="text/html" src="https://www.youtube.com/embed/\#(id)?autoplay=1" frameborder="0"></iframe><style>body{margin:0;}</style>"#, baseURL: nil)
		}
		return view
	}

	func updateUIView(_ uiView: WKWebView, context: Context) {
	}
}
