import Combine
import SwiftUI
import CoreData

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

	let id: String
	let model: SubredditSubscriptionModel

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?

	init(model: SubredditSubscriptionModel) {
		self.id = model.id
		self.model = model
	}

	func updateIfNeeded(in context: NSManagedObjectContext) {
		guard subscription == nil, let period = RedditPeriod.allCases.first(where: { model.needsUpdate(for: $0) }) else {
			return
		}
		fetch(.topPosts(in: model.name, over: period, count: 10)) { result in
			self.model.update(posts: result.values, for: period, in: context)
		}
	}
}
