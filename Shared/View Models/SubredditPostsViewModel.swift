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

	static let global = SubredditPostsViewModel(collection: "$GLOBAL")

	let id: String
	let model: UserSubreddit?

	var request: APIRequest<NetworkResource>?
	var subscription: AnyCancellable?
	var loading = true
	var error: Error?
	var result: NetworkResource?
	let refreshOnAppear = true

	private var context: NSManagedObjectContext?
	private var period: RedditPeriod?

	init(collection id: String) {
		self.id = id
		self.model = nil
	}

	init(model: UserSubreddit, in context: NSManagedObjectContext) {
		self.id = model.id
		self.model = model
		updateIfNeeded(in: context)
	}

	func updateIfNeeded(in context: NSManagedObjectContext) {
		guard let model = model, subscription == nil else {
			return
		}
		let fetchCount = model.fetchCount
		guard model.postCount < max(4, fetchCount) else {
			return
		}
		self.context = context
		var cases = RedditPeriod.allCases
		if model.priority < 1 {
			cases = cases.dropLast()
		}
		period = cases.first(where: model.needsUpdate(for:))
		guard let period = period else {
			return
		}
		fetch(.topPosts(in: model.name, over: period, count: fetchCount))
	}

	func onLoaded(_ result: NetworkResource) {
		if let model = model, let context = context, let period = period {
			model.performUpdate(posts: result.values, for: period, in: context)
		}
	}
}
