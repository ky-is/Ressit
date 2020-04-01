import Foundation
import CoreData

@objc(SubredditSubscription)
final class SubredditSubscription: NSManagedObject, Identifiable {

	@NSManaged public var name: String!
	@NSManaged public var creationDate: Date?
	@NSManaged public var accessDate: Date?

}

extension SubredditSubscription {
	static func create(named name: String, in managedObjectContext: NSManagedObjectContext) -> Self {
		let subredditSubscription = self.init(context: managedObjectContext)
		subredditSubscription.name = name
		subredditSubscription.creationDate = Date()
		managedObjectContext.safeSave()
		return subredditSubscription
	}
}

extension Collection where Element == SubredditSubscription, Index == Int {
	func delete(at indices: IndexSet, from managedObjectContext: NSManagedObjectContext) {
		indices.forEach { managedObjectContext.delete(self[$0]) }
		managedObjectContext.safeSave()
	}
}
