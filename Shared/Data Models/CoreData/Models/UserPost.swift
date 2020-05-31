import Foundation
import CoreData
import Combine

@objc(UserPost)
final class UserPost: NSManagedObject, RedditVotable {
	static let type = "t3"
	internal var saveSubscription: AnyCancellable?
	internal var voteSubscription: AnyCancellable?

	@NSManaged var id: String
	@NSManaged var hashID: String
	@NSManaged var title: String
	@NSManaged var author: String
	@NSManaged var score: Int
	@NSManaged var commentCount: Int
	@NSManaged var creationDate: Date?
	@NSManaged var thumbnail: URL?
	@NSManaged var url: URL?
	@NSManaged var selftext: String?
	@NSManaged var crosspostID: String?
	@NSManaged var crosspostFrom: String?

	@NSManaged var previewURL: URL?
	@NSManaged var previewIsVideo: Bool
	@NSManaged var previewWidth: Float
	@NSManaged var previewHeight: Float

	@NSManaged var userSaved: Bool
	@NSManaged var userVote: Int

	@NSManaged var subreddit: UserSubreddit
	@NSManaged var metadata: UserPostMetadata?

	var thumbnailLoader: ImageDownloadViewModel?

	var isYoutubeLink: Bool {
		url?.hostDescription == "youtube.com"
	}

	func performRead(_ read: Bool, in context: NSManagedObjectContext) {
		context.perform {
			if let metadata = self.metadata {
				metadata.readDate = read ? Date() : nil
				context.refresh(self, mergeChanges: true)
			} else if read {
				UserPostMetadata.create(for: self, in: context)
			}
			context.safeSave()
		}
	}
}

extension UserPost {
	convenience init(post: RedditPost, insertInto context: NSManagedObjectContext) {
		self.init(context: context)
		id = post.id
		hashID = post.hashID
		title = post.title
		author = post.author
		score = post.score
		commentCount = post.commentCount
		creationDate = Date(timeIntervalSince1970: post.createdAt)
		userSaved = post.saved
		userVote = post.likes == true ? 1 : (post.likes == false ? -1 : 0)
		thumbnail = post.thumbnail != nil ? URL(string: post.thumbnail!) : nil
		url = post.url
		crosspostID = post.crosspostID
		crosspostFrom = post.crosspostFrom
		selftext = post.selftext.trimmingCharacters(in: .whitespacesAndNewlines)
		previewURL = post.previewURLs?.first
		previewIsVideo = post.previewIsVideo
		previewWidth = post.previewWidth ?? 0
		previewHeight = post.previewHeight ?? 0
	}

	static func create(for post: RedditPost, subreddit: UserSubreddit, in context: NSManagedObjectContext) {
		let fetchRequest = UserPostMetadata.fetchRequest()
		fetchRequest.predicate = \UserPostMetadata.hashID == post.hashID
		let request = try? context.fetch(fetchRequest) as? [UserPostMetadata]
		let metadata = request?.first
		if metadata?.readDate != nil { //SAMPLE
			return print("Already read", post.title)
		}
		let subredditPost = self.init(post: post, insertInto: context)
		subredditPost.subreddit = subreddit
		subredditPost.metadata = metadata
		metadata?.addToPosts(subredditPost)
		_ = subredditPost.getThumbnailManager()
	}

	func getThumbnailManager() -> ImageDownloadViewModel? {
		guard let thumbnail = thumbnail else {
			return nil
		}
		guard let thumbnailLoader = thumbnailLoader else {
			let loader = ImageDownloadViewModel(url: thumbnail, cacheFor: self, cacheName: "thumb")
			self.thumbnailLoader = loader
			return loader
		}
		return thumbnailLoader
	}
}
