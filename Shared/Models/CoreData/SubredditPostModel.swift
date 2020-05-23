import Foundation
import CoreData

@objc(SubredditPostModel)
final class SubredditPostModel: NSManagedObject, Identifiable {
	@NSManaged var id: String
	@NSManaged var title: String
	@NSManaged var author: String
	@NSManaged var score: Int
	@NSManaged var commentCount: Int
	@NSManaged var creationDate: Date

	@NSManaged var subreddit: SubredditSubscriptionModel

	static private let formatter: RelativeDateTimeFormatter = {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .abbreviated
		formatter.dateTimeStyle = .numeric
		return formatter
	}()

	var creationString: String {
		SubredditPostModel.formatter.localizedString(for: creationDate, relativeTo: Date())
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
		subredditPost.subreddit = subreddit
	}
}
