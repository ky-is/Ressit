import SwiftUI

struct RedditView<VM: RedditViewModel, Content: View>: View {
	@ObservedObject var viewModel: VM
	let loadingHeight: CGFloat?
	let content: (VM.NetworkResource) -> Content

	init(_ viewModel: VM, loadingHeight: CGFloat? = nil, @ViewBuilder successContent: @escaping (VM.NetworkResource) -> Content) {
		self.viewModel = viewModel
		self.loadingHeight = loadingHeight
		self.content = successContent
	}

	var body: some View {
		Group {
			if viewModel.result != nil {
				content(viewModel.result!)
			} else {
				LoadingPlaceholder(label: "Reddit data", error: viewModel.error, loadingHeight: loadingHeight)
			}
		}
			.onAppear(perform: viewModel.fetch)
	}
}
