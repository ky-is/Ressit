import SwiftUI
import CoreData

struct LocalView<VM: RedditViewModel, Result: NSManagedObject & Identifiable, Content: View>: View {
	@ObservedObject var viewModel: VM
	let loadingHeight: CGFloat?
	let content: (FetchedResults<Result>) -> Content

	@FetchRequest private var fetchedResults: FetchedResults<Result>

	init(_ viewModel: VM, loadingHeight: CGFloat? = nil, sortDescriptor: NSSortDescriptor, predicate: NSPredicate, @ViewBuilder successContent: @escaping (FetchedResults<Result>) -> Content) {
		self.viewModel = viewModel
		self.loadingHeight = loadingHeight
		self.content = successContent
		self._fetchedResults = FetchRequest<Result>(sortDescriptors: [sortDescriptor], predicate: predicate)
	}

	var body: some View {
		Group {
			if !fetchedResults.isEmpty {
				content(fetchedResults)
			} else {
				LoadingPlaceholder(error: viewModel.error, loadingHeight: loadingHeight)
			}
		}
			.onAppear(perform: viewModel.fetch)
	}
}
