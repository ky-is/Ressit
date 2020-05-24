import Foundation

struct RedditPostComments: RedditResponsable {
//	let post: RedditListing<SubredditPost>
	let comments: RedditListing<SubredditPostComment>

	init(json: Any) {
		let children = json as! [[String: Any]]
//		post = RedditListing<SubredditPost>(json: children[0])
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

struct Subreddit: RedditResponsable, Identifiable {
	let id: String
	let name: String

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		id = data["id"] as! String
		name = data["display_name"] as! String
	}
}

struct SubredditPost: RedditResponsable, Identifiable {
	let id: String
	let title: String
	let author: String
	let score: Int
	let commentCount: Int
	let createdAt: TimeInterval
	let editedAt: TimeInterval?
	let text: String?
	let url: String?

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
		url = data["url"] as? String
	}
}

struct SubredditPostComment: RedditResponsable, Identifiable {
	let id: String
	let author: String?
	let body: String?
	let creationDate: Date?
	let editedAt: TimeInterval?
	let score: Int?
	let replies: RedditListing<SubredditPostComment>?
	let childIDs: [String]?

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
			if author == "[deleted]" { //TODO && childIDs == nil, if we want to be able to load replies to deleted posts
				return nil
			}
			replies = nil
		}
		self.author = author

		id = data["id"] as! String
		body = data["body"] as? String
		let editTimestamp = data["edited"] as? TimeInterval ?? 0
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		score = data["score"] as? Int

	}
}
