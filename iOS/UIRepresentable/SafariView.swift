import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
		let controller = SFSafariViewController(url: url)
		controller.preferredControlTintColor = .tint
		return controller
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<Self>) {
	}
}
