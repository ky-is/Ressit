import Foundation
import CoreData
import Combine

@objc(SubredditPostModel)
final class SubredditPostModel: NSManagedObject, RedditVotable {
	static let type = "t3"

	@NSManaged var id: String
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

	@NSManaged var subreddit: SubredditSubscriptionModel
	@NSManaged var metadata: SubredditPostMetadataModel?

	private var saveSubscription: AnyCancellable?
	private var voteSubscription: AnyCancellable?

	var thumbnailLoader: ImageDownloadManager?

	func toggleRead(_ read: Bool, in context: NSManagedObjectContext) {
		if let metadata = metadata {
			metadata.readDate = read ? Date() : nil
			context.refresh(self, mergeChanges: true)
		} else if read {
			SubredditPostMetadataModel.create(for: self, in: context)
		}
	}
	func toggleVote(_ vote: Int, in context: NSManagedObjectContext) {
		performRemoteUpdate(on: \.userVote, updateTo: vote, request: .vote(entity: self, vote: vote), in: context)
	}
	func performSaved(_ saved: Bool, in context: NSManagedObjectContext) {
		performRemoteUpdate(on: \.userSaved, updateTo: saved, request: .save(entity: self, enabled: saved), in: context)
	}

	private func performRemoteUpdate<Value>(on keyPath: ReferenceWritableKeyPath<SubredditPostModel, Value>, updateTo value: Value, request: APIRequest<EmptyReddit>, in context: NSManagedObjectContext) {
		let oldValue = self[keyPath: keyPath]
		saveSubscription?.cancel()
		context.perform {
			self[keyPath: keyPath] = value
			context.safeSave()
		}
		self.saveSubscription = RedditClient.shared.send(request)
			.sink(receiveCompletion: { completion in
				switch completion {
				case .failure(let error):
					print("Undo", keyPath, self.title, oldValue, error)
					context.perform {
						self[keyPath: keyPath] = oldValue
						context.safeSave()
					}
				case .finished:
					break
				}
			}, receiveValue: { _ in })

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
		subredditPost.thumbnail = post.thumbnail != nil ? URL(string: post.thumbnail!) : nil
		subredditPost.url = post.url
		subredditPost.crosspostID = post.crosspostID
		subredditPost.crosspostFrom = post.crosspostFrom
		subredditPost.selftext = post.selftext?.trimmingCharacters(in: .whitespacesAndNewlines)
		subredditPost.previewURL = post.previewURLs?.first
		subredditPost.previewIsVideo = post.previewIsVideo
		subredditPost.previewWidth = post.previewWidth ?? 0
		subredditPost.previewHeight = post.previewHeight ?? 0
		_ = subredditPost.getThumbnailManager()
	}

	func getThumbnailManager() -> ImageDownloadManager? {
		guard let thumbnail = thumbnail else {
			return nil
		}
		guard let thumbnailLoader = thumbnailLoader else {
			let loader = ImageDownloadManager(id: id, url: thumbnail, cache: true)
			self.thumbnailLoader = loader
			return loader
		}
		return thumbnailLoader
	}
}
