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
	typealias NetworkResource = RedditListing<RedditPost>

	static let global = SubredditPostsViewModel(model: nil)

	let id: String
	let model: UserSubreddit?

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?

	private var context: NSManagedObjectContext?
	private var period: RedditPeriod?

	init(model: UserSubreddit?) {
		self.id = model?.id ?? "$GLOBAL"
		self.model = model
	}

	func updateIfNeeded(in context: NSManagedObjectContext) {
		guard let model = model, subscription == nil, model.postCount < 5 else { //TODO 5 is priority dependant
			return
		}
		self.context = context
		self.period = RedditPeriod.allCases.first(where: model.needsUpdate(for:))
		guard let period = period else {
			return
		}
		fetch(.topPosts(in: model.name, over: period, count: 5))
	}

	func onLoaded(_ result: NetworkResource) {
		if let model = model, let context = context, let period = period {
			model.performUpdate(posts: result.values, for: period, in: context)
		}
	}
}
