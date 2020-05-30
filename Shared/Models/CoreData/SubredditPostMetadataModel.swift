import Foundation
import CoreData

@objc(SubredditPostMetadataModel)
class SubredditPostMetadataModel: NSManagedObject {
	@NSManaged var readDate: Date?
	@NSManaged var hashID: String

	@NSManaged var posts: Set<SubredditPostModel>
}

extension SubredditPostMetadataModel {
	static func create(for post: SubredditPostModel, in context: NSManagedObjectContext) {
		let metadata = self.init(context: context)
		metadata.hashID = post.hashID
		metadata.readDate = Date()
		metadata.addToPosts(post)
	}
}

extension SubredditPostMetadataModel {
	@objc(addPostsObject:)
	@NSManaged public func addToPosts(_ value: SubredditPostModel)

	@objc(removePostsObject:)
	@NSManaged func removeFromPosts(_ value: SubredditPostModel)

	@objc(addPosts:)
	@NSManaged func addToPosts(_ values: NSSet)

	@objc(removePosts:)
	@NSManaged func removeFromPosts(_ values: NSSet)
}
