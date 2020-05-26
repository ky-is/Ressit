import Foundation
import CoreData

@objc(SubredditSubscriptionModel)
final class SubredditSubscriptionModel: NSManagedObject, RedditIdentifiable {
	static let type = "t5"

	@NSManaged var id: String
	@NSManaged var name: String
	@NSManaged var creationDate: Date?
	@NSManaged var accessDate: Date?

	@NSManaged var periodAllDate: Date?
	@NSManaged var periodYearDate: Date?
	@NSManaged var periodMonthDate: Date?
	@NSManaged var periodWeekDate: Date?
	@NSManaged var postCount: Int

	@NSManaged var posts: Set<SubredditPostModel>

	func needsUpdate(for period: RedditPeriod) -> Bool {
		let date: Date?
		switch period {
		case .all:
			date = periodAllDate
		case .year:
			date = periodYearDate
		case .month:
			date = periodMonthDate
		case .week:
			date = periodWeekDate
		}
		guard let previousDate = date else {
			return true
		}
		return previousDate.timeIntervalSinceNow > period.minimumUpdate
	}

	func performUpdate(posts: [SubredditPost], for period: RedditPeriod, in context: NSManagedObjectContext) {
		context.perform {
			posts.forEach { SubredditPostModel.create(for: $0, subreddit: self, in: context) }
			let date = Date()
			switch period {
			case .all:
				self.periodAllDate = date
			case .year:
				self.periodYearDate = date
			case .month:
				self.periodMonthDate = date
			case .week:
				self.periodWeekDate = date
			}
			context.safeSave()
			context.refresh(self, mergeChanges: true)
		}
	}
}

extension SubredditSubscriptionModel {
	static func create(for subreddit: Subreddit, in context: NSManagedObjectContext) {
		let subredditSubscription = self.init(context: context)
		subredditSubscription.id = subreddit.id
		subredditSubscription.name = subreddit.name
		subredditSubscription.creationDate = Date()
	}
}

extension Collection where Element == SubredditPostsViewModel, Index == Int {
	func performDelete(at indices: IndexSet, from context: NSManagedObjectContext) {
		if !indices.isEmpty {
			context.perform {
				indices.forEach { context.delete(self[$0].model!) }
				context.safeSave()
			}
		}
	}
}
