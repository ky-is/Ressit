import UIKit
import Combine
import SwiftUI
import AVKit

struct VideoViewer: UIViewControllerRepresentable {
	let url: URL
	@Binding var aspectRatio: CGFloat

	private let controller: AVPlayerViewController
	private var sizeSubscription: AnyCancellable?

	init(url: URL, aspectRatio: Binding<CGFloat>) {
		self.url = url
		self._aspectRatio = aspectRatio
		let controller = AVPlayerViewController()
		self.controller = controller
		self.sizeSubscription = controller.publisher(for: \.videoBounds)
			.filter { $0.height > 0 }
			.map { $0.width / $0.height }
			.receive(on: RunLoop.main)
			.assign(to: \.aspectRatio, on: self)
	}

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> AVPlayerViewController {
		let player = AVPlayer(url: url)
		controller.player = player
		player.play()
		return controller
	}

	func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<Self>) {
	}
}

struct VideoViewer_Previews: PreviewProvider {
	static let post = RedditListing<RedditPost>(asset: .posts).values.first!

	static var previews: some View {
		VideoViewer(url: post.previewURLs!.first!, aspectRatio: .constant(CGFloat(post.previewWidth! / post.previewHeight!)))
	}
}
