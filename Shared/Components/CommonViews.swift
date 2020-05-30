import SwiftUI
import SafariServices

struct SubredditTitle: View {
	let name: String?

	var body: some View {
		Group {
			if name != nil {
				HStack(spacing: 1) {
					Text("r/")
						.foregroundColor(.secondary)
					Text(name!)
				}
					.lineLimit(1)
			} else {
				Text("🌏 Global Feed")
			}
		}
	}
}

struct HiddenNavigationLink<Destination: View>: View {
	let isActive: Bool
	let destination: Destination

	var body: some View {
		NavigationLink(destination: destination, isActive: .constant(isActive)) {
			EmptyView()
		}
			.hidden()
	}
}

struct IconText: View {
	let iconName: String
	let label: String

	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: iconName)
				.foregroundColor(.secondary)
			Text(label)
		}
	}
}

struct ScoreMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: "arrow.up")
				.foregroundColor(entity.voteColor())
				.animation(.default)
				.rotationEffect(entity.userVote < 0 ? .degrees(180) : .zero)
			Text(entity.score.description)
		}
	}
}

struct SafariView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
		return SFSafariViewController(url: url)
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<Self>) {
	}
}

struct LoadingView: View {
	var body: some View {
		Image(systemName: "ellipsis")
			.font(.largeTitle)
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

final class ScrollImageViewController: UIViewController, UIScrollViewDelegate {
	var imageView: UIImageView?

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		imageView
	}
}
