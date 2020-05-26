import Foundation
import CoreData

@objc(SubredditPostModel)
final class SubredditPostModel: NSManagedObject, RedditIdentifiable {
	static let type = "t3"

	@NSManaged var id: String
	@NSManaged var title: String
	@NSManaged var author: String
	@NSManaged var score: Int
	@NSManaged var commentCount: Int
	@NSManaged var creationDate: Date

	@NSManaged var userSaved: Bool
	@NSManaged var userVote: Int

	@NSManaged var subreddit: SubredditSubscriptionModel
	@NSManaged var metadata: SubredditPostMetadataModel?

	func toggleRead(_ read: Bool, in context: NSManagedObjectContext) {
		if let metadata = metadata {
			metadata.readDate = read ? Date() : nil
			context.refresh(self, mergeChanges: true)
		} else if read {
			SubredditPostMetadataModel.create(for: self, in: context)
		}
	}
	func toggleVote(_ vote: Int) {
		self.userVote = vote
	}
	func toggleSaved(_ saved: Bool) {
		self.userSaved = saved
	}
}

extension SubredditPostModel {
	static func create(for post: SubredditPost, subreddit: SubredditSubscriptionModel, in context: NSManagedObjectContext) {
		let subredditPost = self.init(context: context)
		subredditPost.id = post.id
		subredditPost.title = post.title
		subredditPost.author = post.author
		subredditPost.score = post.score
		subredditPost.commentCount = post.commentCount
		subredditPost.creationDate = Date(timeIntervalSince1970: post.createdAt)
		subredditPost.userSaved = post.saved
		subredditPost.userVote = post.likes == true ? 1 : (post.likes == false ? -1 : 0)
		subredditPost.subreddit = subreddit
	}
}
