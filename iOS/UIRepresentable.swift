import SwiftUI
import SafariServices

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
		imageView
	}
}
