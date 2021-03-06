import Combine
import SwiftUI

final class SubredditsMineViewModel: RedditViewModel {
	typealias NetworkResource = RedditListing<RedditSubreddit>

	static let shared = SubredditsMineViewModel()

	var request: APIRequest<NetworkResource>? = .subredditsMine
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?
	let refreshOnAppear = true
}

final class SubredditsSearchViewModel: RedditViewModel {
	typealias NetworkResource = RedditListing<RedditSubreddit>

	@Published var query = ""
	var querySubscription: AnyCancellable?

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?
	let refreshOnAppear = true

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

final class SubredditPostCommentsViewModel: RedditViewModel {
	typealias NetworkResource = RedditPostComments

	static var latest: SubredditPostCommentsViewModel?

	let id: String

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?
	let refreshOnAppear = false

	init(post: UserPost) {
		self.id = post.id
		self.request = .comments(for: post)
		Self.latest = self
	}
}
