import SwiftUI
import SafariServices
import WebKit

struct SafariView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
		return SFSafariViewController(url: url)
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<Self>) {
	}
}

struct ScrollImageView: UIViewControllerRepresentable {
	let image: UIImage
	let width: CGFloat
	let height: CGFloat
	let geometry: GeometryProxy

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> ScrollImageViewController {
		let controller = ScrollImageViewController()
		let imageView = UIImageView(image: image)
		imageView.contentMode = .scaleAspectFit
		imageView.frame.size = geometry.size
		let aspectRatio = width / height
		if aspectRatio > 1 {
			imageView.frame.size.height /= aspectRatio
		} else {
			imageView.frame.size.width /= aspectRatio
		}
		let scroller = UIScrollView()
		scroller.delegate = controller
		scroller.minimumZoomScale = 1
		scroller.maximumZoomScale = 3

		controller.view = scroller
		scroller.addSubview(imageView)
		controller.imageView = imageView
		return controller
	}

	func updateUIViewController(_ uiViewController: ScrollImageViewController, context: UIViewControllerRepresentableContext<Self>) {
	}
}

internal final class ScrollImageViewController: UIViewController, UIScrollViewDelegate {
	var imageView: UIImageView?

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
}

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

struct BlurView: UIViewRepresentable {
	let style: UIBlurEffect.Style

	func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIView {
		let view = UIView(frame: .zero)
		view.backgroundColor = .clear
		let blurEffect = UIBlurEffect(style: style)
		let blurView = UIVisualEffectView(effect: blurEffect)
		blurView.translatesAutoresizingMaskIntoConstraints = false
		view.insertSubview(blurView, at: 0)
		NSLayoutConstraint.activate([
			blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
			blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
		])
		return view
	}

	func updateUIView(_ uiView: UIView,context: UIViewRepresentableContext<BlurView>) {
	}
}

struct UIRepresentable_Previews: PreviewProvider {
	static var previews: some View {
		BlurView(style: .systemChromeMaterial)
	}
}

