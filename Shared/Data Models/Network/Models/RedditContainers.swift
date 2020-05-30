import Foundation

struct EmptyReddit: RedditResponsable {
	init(json: Any) {
		guard let data = json as? [String: Any], data.isEmpty else {
			fatalError("Invalid empty response: \(json)")
		}
	}
}

struct RedditPostComments: RedditResponsable {
	let post: RedditPost
	let comments: RedditListing<RedditComment>

	init(json: Any) {
		let children = json as! [[String: Any]]
//		print(children[0]) //SAMPLE post
		post = RedditListing<RedditPost>(json: children[0]).values.first!
		comments = RedditListing<RedditComment>(json: children[1])
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
