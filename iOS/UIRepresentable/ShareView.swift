import SwiftUI

struct ShareSheet: UXViewControllerRepresentable {
	let activityItems: [Any]
	let applicationActivities: [UIActivity]? = nil
	let excludedActivityTypes: [UIActivity.ActivityType]? = nil
	let callback: UIActivityViewController.CompletionWithItemsHandler? = nil

	func makeUIViewController(context: Context) -> UIActivityViewController {
		let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
		controller.excludedActivityTypes = excludedActivityTypes
		controller.completionWithItemsHandler = callback
		return controller
	}

	func updateUIViewController(_ viewController: UIActivityViewController, context: Context) {}
}
