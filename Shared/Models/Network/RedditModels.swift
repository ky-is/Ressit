import Foundation

struct RedditListing<Value: RedditResponsable>: RedditResponsable {
	let after: String?
	let before: String?
	let values: [Value]

	init(json: [String: Any]) {
		after = json["after"] as? String
		before = json["after"] as? String
		let children = json["children"] as! [[String: Any]]
		values = children.map(Value.init(json:))
	}
}

struct Subreddit: RedditResponsable, Identifiable {
	let id: String
	let name: String

	init(json: [String: Any]) {
		let data = json["data"] as! [String: Any]
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

	init(json: [String: Any]) {
		let data = json["data"] as! [String: Any]
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
