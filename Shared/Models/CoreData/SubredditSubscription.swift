import Foundation
import CoreData

@objc(SubredditSubscription)
final class SubredditSubscription: NSManagedObject, Identifiable {
	@NSManaged var id: String
	@NSManaged var name: String
	@NSManaged var creationDate: Date?
	@NSManaged var accessDate: Date?

	@NSManaged var periodAllDate: Date?
	@NSManaged var periodYearDate: Date?
	@NSManaged var periodMonthDate: Date?
	@NSManaged var periodWeekDate: Date?

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

	func markUpdated(for period: RedditPeriod) {
		let date = Date()
		switch period {
		case .all:
			periodAllDate = date
		case .year:
			periodYearDate = date
		case .month:
			periodMonthDate = date
		case .week:
			periodWeekDate = date
		}
	}
}

extension SubredditSubscription {
	static func create(for subreddit: Subreddit, in managedObjectContext: NSManagedObjectContext) {
		let subredditSubscription = self.init(context: managedObjectContext)
		subredditSubscription.id = subreddit.id
		subredditSubscription.name = subreddit.name
		subredditSubscription.creationDate = Date()
		managedObjectContext.safeSave()
	}
}

extension Collection where Element == SubscriptionViewModel, Index == Int {
	func delete(at indices: IndexSet, from managedObjectContext: NSManagedObjectContext) {
		if !indices.isEmpty {
			indices.forEach { managedObjectContext.delete(self[$0].model) }
			managedObjectContext.safeSave()
		}
	}
}
