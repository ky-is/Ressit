import Combine
import SwiftUI

enum RedditPeriod: String, CaseIterable {
	case all, year, month, week

	var minimumUpdate: TimeInterval {
		switch self {
		case .week:
			return .day
		case .month:
			return .week
		case .year:
			return .month
		case .all:
			return .year
		}
	}
}

protocol RedditViewModel: ObservableObject {
	associatedtype NetworkResource: RedditResponsable

	var objectWillChange: ObservableObjectPublisher { get }
	var request: APIRequest<NetworkResource>? { get set }
	var subscription: AnyCancellable? { get set }
	var loading: Bool { get set }
	var error: Error? { get set }
	var result: NetworkResource? { get set }

	func fetch()
	func fetch(_: APIRequest<NetworkResource>) -> AnyPublisher<Self.NetworkResource, Error>?
}

extension RedditViewModel {
	func fetch() {
		guard let request = request ?? self.request else {
			return
		}
		_ = fetch(request)
	}

	@discardableResult func fetch(_ request: APIRequest<NetworkResource>) -> AnyPublisher<Self.NetworkResource, Error>? {
		guard subscription == nil else {
			return nil
		}
		self.request = request
		loading = true
		let publisher = RedditClient.shared.send(request)
		subscription = publisher
			.receive(on: RunLoop.main)
			.sink(receiveCompletion: { completion in
				self.subscription = nil
				self.loading = false
				switch completion {
				case .failure(let error):
					print(error)
					self.error = error
				case .finished:
					break
				}
				self.objectWillChange.send()
			}, receiveValue: { result in
				self.result = result
			})
		return publisher
	}
}

final class SubredditsMineViewModel: RedditViewModel {
	typealias NetworkResource = RedditListing<Subreddit>

	static let shared = SubredditsMineViewModel()

	var request: APIRequest<NetworkResource>? = .subredditsMine
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?
}

final class SubredditsSearchViewModel: RedditViewModel {
	typealias NetworkResource = RedditListing<Subreddit>

	@Published var query = ""
	var querySubscription: AnyCancellable?

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?

	init() {
		querySubscription = $query
			.removeDuplicates()
			.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
			.map { $0.starts(with: "r/") ? String($0.dropFirst(2)) : $0 }
			.filter { $0.isEmpty || $0.count >= 2 }
			.sink { value in
				if value.isEmpty {
					self.result = nil
					self.objectWillChange.send()
				} else {
					self.fetch(.subreddits(search: value))
				}
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

final class SubscriptionViewModel: RedditViewModel, Identifiable {
	typealias NetworkResource = RedditListing<SubredditPost>

	let model: SubredditSubscription
	var updateSubscription: AnyCancellable?

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?

	init(model: SubredditSubscription) {
		self.model = model
	}

	func updateIfNeeded() {
		guard let period = RedditPeriod.allCases.first(where: { model.needsUpdate(for: $0) }) else {
			return
		}
		if let publisher = fetch(.topPosts(in: model.name, over: period)) {
			updateSubscription = publisher
				.sink(receiveCompletion: { _ in }) { _ in
					self.model.markUpdated(for: period)
				}
			print(#function, model.name, period)
		}
	}
}
