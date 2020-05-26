import Foundation

struct EmptyReddit: RedditResponsable {
	init(json: Any) {
		guard let data = json as? [String: Any], data.isEmpty else {
			fatalError("Invalid empty response: \(json)")
		}
	}
}

struct RedditPostComments: RedditResponsable {
	let post: SubredditPost
	let comments: RedditListing<SubredditPostComment>

	init(json: Any) {
		let children = json as! [[String: Any]]
		post = RedditListing<SubredditPost>(json: children[0]).values.first!
		comments = RedditListing<SubredditPostComment>(json: children[1])
	}
}

struct RedditListing<Value: RedditResponsable>: RedditResponsable {
	let after: String?
	let before: String?
	let values: [Value]

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		after = data["after"] as? String
		before = data["after"] as? String
		let children = data["children"] as! [[String: Any]]
		values = children.compactMap(Value.init(json:))
	}
}

struct Subreddit: RedditResponsable, RedditIdentifiable {
	static let type = "t5"

	let id: String
	let name: String

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		id = data["id"] as! String
		name = data["display_name"] as! String
	}
}

struct SubredditPost: RedditResponsable, RedditIdentifiable {
	static let type = "t3"

	let id: String
	let title: String
	let author: String
	let score: Int
	let commentCount: Int
	let createdAt: TimeInterval
	let editedAt: TimeInterval?
	let text: String?
	let saved: Bool
	let likes: Bool?
	let url: URL?
	let thumbnail: String?

	let previewURLs: [URL]?
	let previewIsVideo: Bool
	let previewWidth: Float?
	let previewHeight: Float?

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		id = data["id"] as! String
		title = data["title"] as! String
		author = data["author"] as! String
		score = data["score"] as! Int
		commentCount = data["num_comments"] as! Int
		createdAt = data["created"] as! TimeInterval
		let editTimestamp = data["edited"] as! TimeInterval
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		text = data["selftext"] as? String
		let urlString = data["url"] as? String
		url = urlString != nil ? URL(string: urlString!) : nil
		saved = data["saved"] as! Bool
		likes = data["likes"] as? Bool
		thumbnail = data["thumbnail"] as? String
		var previewURLStrings: [String]?
		var isPreviewVideo = false
		var previewWidth: Float?, previewHeight: Float?
		if let previews = data["preview"] as? [String: Any] {
			if let videoPreview = previews["reddit_video_preview"] as? [String: Any] {
				if let urlString = (videoPreview["hls_url"] ?? videoPreview["fallback_url"]) as? String {
					isPreviewVideo = true
					previewURLStrings = [urlString]
					previewWidth = videoPreview["width"] as? Float
					previewHeight = videoPreview["height"] as? Float
				} else {
					print("reddit_video_preview", videoPreview)
				}
			}
			if previewURLStrings == nil, let images = previews["images"] as? [[String: Any]] {
				previewURLStrings = images.compactMap { image in
					guard let source = image["source"] as? [String: Any], let urlString = source["url"] as? String else {
						print("images", image)
						return nil
					}
					if previewWidth == nil {
						previewWidth = source["width"] as? Float
						previewHeight = source["height"] as? Float
					}
					return urlString
				}
			}
		}
		self.previewURLs = previewURLStrings?.compactMap(URL.init(string:)).nonEmpty
		self.previewIsVideo = isPreviewVideo
		self.previewWidth = previewWidth
		self.previewHeight = previewHeight
	}
}

final class SubredditPostComment: RedditResponsable, RedditVotable {
	static let type = "t1"

	let id: String
	let author: String?
	let body: String?
	let creationDate: Date?
	let editedAt: TimeInterval?
	let score: Int
	let replies: RedditListing<SubredditPostComment>?
	let childIDs: [String]?

	@Published var userVote: Int

	init?(json: Any) {
		let data = Self.defaultJSONData(json)

		let created = data["created"] as? TimeInterval
		let creationDate = created != nil ? Date(timeIntervalSince1970: created!) : nil
		self.creationDate = creationDate

		let childIDs = data["children"] as? [String]
		if childIDs?.isEmpty ?? false {
			if creationDate != nil {
				print("INVALID CHILDREN", data)
			}
			return nil
		}
		self.childIDs = childIDs

		let author = data["author"] as? String
		if let rawReplies = data["replies"] as? [String: Any] {
			replies = RedditListing<SubredditPostComment>(json: rawReplies)
		} else {
			replies = nil
		}
		if replies?.values.nonEmpty == nil && (author == nil || author == "[deleted]") { //TODO && childIDs == nil, if we want to be able to load replies to deleted posts
			return nil
		}
		self.author = author

		id = data["id"] as! String
		body = data["body"] as? String
		let editTimestamp = data["edited"] as? TimeInterval ?? 0
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		score = data["score"] as? Int ?? 0
		let likes = data["likes"] as? Bool
		userVote = likes == true ? 1 : (likes == false ? -1 : 0)
	}

	var deleted: Bool {
		author == nil || author == "[deleted]"
	}
}
