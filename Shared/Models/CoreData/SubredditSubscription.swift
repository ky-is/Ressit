import Foundation
import CoreData

@objc(SubredditSubscription)
final class SubredditSubscription: NSManagedObject, Identifiable {
	@NSManaged public var id: String
	@NSManaged public var name: String
	@NSManaged public var creationDate: Date?
	@NSManaged public var accessDate: Date?
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

extension Collection where Element == SubredditSubscription, Index == Int {
	func delete(at indices: IndexSet, from managedObjectContext: NSManagedObjectContext) {
		if !indices.isEmpty {
			indices.forEach { managedObjectContext.delete(self[$0]) }
			managedObjectContext.safeSave()
		}
	}
}
