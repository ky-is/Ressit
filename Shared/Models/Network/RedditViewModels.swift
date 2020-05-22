import Combine
import SwiftUI

protocol RedditViewModel: ObservableObject {
	associatedtype NetworkResource: RedditResponsable

	var objectWillChange: ObservableObjectPublisher { get }
	var request: APIRequest<NetworkResource>? { get set }
	var subscription: AnyCancellable? { get set }
	var loading: Bool { get set }
	var error: Error? { get set }
	var result: NetworkResource? { get set }

	func fetch()
}

extension RedditViewModel {
	func fetch() {
		guard let request = request, subscription == nil else {
			return
		}
		loading = true
		subscription = RedditClient.shared.send(request)
			.receive(on: RunLoop.main)
			.sink(receiveCompletion: { completion in
				self.subscription = nil
				self.loading = false
				switch completion {
				case .failure(let error):
					print(error)
					self.error = error
					self.objectWillChange.send()
				case .finished:
					break
				}
			}, receiveValue: { result in
				self.result = result
				self.objectWillChange.send()
			})
	}
}

final class SubredditsMineViewModel: RedditViewModel {
	static let shared = SubredditsMineViewModel()

	var request: APIRequest<RedditListing<Subreddit>>? = .subredditsMine
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: RedditListing<Subreddit>?
}

final class SubredditsSearchViewModel: RedditViewModel {
	@Published var query = ""
	var querySubscription: AnyCancellable?

	var request: APIRequest<RedditListing<Subreddit>>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: RedditListing<Subreddit>?

	init() {
		querySubscription = $query
			.removeDuplicates()
			.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
			.map { $0.starts(with: "r/") ? String($0.dropFirst(2)) : $0 }
			.filter { $0.count > 2 }
			.sink { value in
				self.request = .subreddits(search: value)
				self.fetch()
			}
	}
}

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
