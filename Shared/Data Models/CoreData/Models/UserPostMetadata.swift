import Foundation
import CoreData

@objc(UserPostMetadata)
class UserPostMetadata: NSManagedObject {
	@NSManaged var readDate: Date?
	@NSManaged var hashID: String

	@NSManaged var posts: Set<UserPost>
}

extension UserPostMetadata {
	static func create(for post: UserPost, in context: NSManagedObjectContext) {
		let metadata = self.init(context: context)
		metadata.hashID = post.hashID
		metadata.readDate = Date()
		metadata.addToPosts(post)
	}
}

extension UserPostMetadata {
	@objc(addPostsObject:)
	@NSManaged public func addToPosts(_ value: UserPost)

	@objc(removePostsObject:)
	@NSManaged func removeFromPosts(_ value: UserPost)

	@objc(addPosts:)
	@NSManaged func addToPosts(_ values: NSSet)

	@objc(removePosts:)
	@NSManaged func removeFromPosts(_ values: NSSet)
}
