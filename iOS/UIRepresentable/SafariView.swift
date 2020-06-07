import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: Context) -> SFSafariViewController {
		let controller = SFSafariViewController(url: url)
		controller.preferredControlTintColor = .tint
		return controller
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
