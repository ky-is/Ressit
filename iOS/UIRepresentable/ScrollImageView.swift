import SwiftUI

struct ScrollImageView: UIViewControllerRepresentable {
	let image: UXImage
	let width: CGFloat
	let height: CGFloat
	let geometry: GeometryProxy

	func makeUIViewController(context: Context) -> ScrollImageViewController {
		let controller = ScrollImageViewController()
		let imageView = UXImageView(image: image)
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

	func updateUIViewController(_ uiViewController: ScrollImageViewController, context: Context) {}
}

internal final class ScrollImageViewController: UIViewController, UIScrollViewDelegate {
	var imageView: UXImageView?

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}
}
