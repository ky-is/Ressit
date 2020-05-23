import Combine
import SwiftUI

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

final class SubredditPostCommentsViewModel: RedditViewModel {
	typealias NetworkResource = RedditListing<SubredditPostComment>

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?

	init(post: SubredditPostModel) {
		request = .comments(for: post)
	}
}
