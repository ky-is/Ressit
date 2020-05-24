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
		values = children.map(Value.init(json:))
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
	let author: String
	let text: String
	let creationDate: Date
	let editedAt: TimeInterval?
	let score: Int
	let replies: RedditListing<SubredditPostComment>?

	init(json: Any) {
		let data = Self.defaultJSONData(json)
		id = data["id"] as! String
		author = data["author"] as! String
		text = data["body"] as! String
		creationDate = Date(timeIntervalSince1970: data["created"] as! TimeInterval)
		let editTimestamp = data["edited"] as! TimeInterval
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		score = data["score"] as! Int
		if let rawReplies = data["replies"] as? [String: Any] {
			replies = RedditListing<SubredditPostComment>(json: rawReplies)
		} else {
			replies = nil
		}
	}
}
