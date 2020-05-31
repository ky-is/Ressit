import SwiftUI
import CoreData

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
				LoadingPlaceholder(error: viewModel.error, loadingHeight: loadingHeight)
			}
		}
			.onAppear(perform: viewModel.fetch)
	}
}

private struct LoadingPlaceholder: View {
	let error: Error?
	let loadingHeight: CGFloat?

	private var content: some View {
		Group {
			if error != nil {
				Text(error!.localizedDescription)
			} else {
				LoadingView()
			}
		}
			.frame(maxWidth: .infinity)
	}

	var body: some View {
		Group {
			if loadingHeight != nil {
				content
					.frame(minHeight: loadingHeight)
			} else {
				Spacer()
				content
				Spacer()
			}
		}
	}
}

struct LocalView<VM: RedditViewModel, Result: NSManagedObject & Identifiable, Content: View>: View {
	@ObservedObject var viewModel: VM
	let content: (FetchedResults<Result>) -> Content

	@FetchRequest private var fetchedResults: FetchedResults<Result>
	@Environment(\.managedObjectContext) private var context

	init(_ viewModel: VM, sortDescriptor: NSSortDescriptor, predicate: NSPredicate, @ViewBuilder successContent: @escaping (FetchedResults<Result>) -> Content) {
		self.viewModel = viewModel
		self.content = successContent
		self._fetchedResults = FetchRequest<Result>(sortDescriptors: [sortDescriptor], predicate: predicate)
	}

	var body: some View {
		Group {
			if !fetchedResults.isEmpty {
				content(fetchedResults)
			} else if viewModel.error != nil {
				Spacer()
				Text(viewModel.error!.localizedDescription)
				Spacer()
			} else if viewModel.loading {
				Spacer()
				LoadingView()
				Spacer()
			}
		}
			.onAppear(perform: viewModel.fetch)
	}
}
