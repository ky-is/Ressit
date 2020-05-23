import SwiftUI

struct RedditView<VM: RedditViewModel, Content: View>: View {
	@ObservedObject var viewModel: VM
	let content: (VM.NetworkResource) -> Content

	init(_ viewModel: VM, @ViewBuilder successContent: @escaping (VM.NetworkResource) -> Content) {
		self.viewModel = viewModel
		self.content = successContent
	}

	var body: some View {
		Group {
			if viewModel.result != nil {
				content(viewModel.result!)
			} else if viewModel.error != nil {
				Spacer()
				Text(viewModel.error!.localizedDescription)
				Spacer()
			} else if viewModel.loading {
				Spacer()
				Text("⋯")
					.font(.title)
				Spacer()
			}
		}
		.onAppear(perform: viewModel.fetch)
	}
}
