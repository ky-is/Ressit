import SwiftUI
import CoreData

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
				LoadingView()
				Spacer()
			}
		}
			.onAppear(perform: viewModel.fetch)
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
