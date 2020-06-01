import Foundation
import CoreData

@objc(UserSubreddit)
final class UserSubreddit: NSManagedObject, RedditIdentifiable {
	typealias PeriodDate = (period: RedditPeriod, date: Date)
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

	@NSManaged var priority: Int

	@NSManaged var posts: Set<UserPost>


	var fetchCount: Int {
		2 + priority * 2
	}

	private func nextDate(for period: RedditPeriod) -> Date? {
		switch period {
		case .all:
			return periodAllDate?.advanced(by: RedditPeriod.all.minimumUpdate)
		case .year:
			return periodYearDate?.advanced(by: RedditPeriod.year.minimumUpdate)
		case .month:
			return periodMonthDate?.advanced(by: RedditPeriod.month.minimumUpdate)
		case .week:
			return periodWeekDate?.advanced(by: RedditPeriod.week.minimumUpdate)
		}
	}

	var nextMostFrequentUpdate: PeriodDate {
		let minPeriod: RedditPeriod = priority > 0 ? .week : .month
		guard periodWeekDate != nil else {
			return (minPeriod, Date())
		}
		return (minPeriod, nextDate(for: minPeriod)!)
	}

	var nextUpdate: PeriodDate {
		guard periodAllDate != nil, periodYearDate != nil, periodMonthDate != nil, periodWeekDate != nil else {
			return (.all, Date())
		}
		let periods: [RedditPeriod] = [.all, .year, .month, .week]
		return periods.map({ ($0, nextDate(for: $0)!) }).sorted { $0.date < $1.date }.first!
	}

	func needsUpdate(for period: RedditPeriod) -> Bool {
		guard let nextDate = nextDate(for: period) else {
			return true
		}
		return nextDate.timeIntervalSinceNow < 0
	}

	func performUpdate(posts: [RedditPost], for period: RedditPeriod, in context: NSManagedObjectContext) {
		context.perform {
			posts.forEach { UserPost.create(for: $0, subreddit: self, in: context) }
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

extension UserSubreddit {
	static func create(for subreddit: RedditSubreddit, in context: NSManagedObjectContext) {
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
