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

final class SubredditPostsViewModel: RedditViewModel, Identifiable {
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
