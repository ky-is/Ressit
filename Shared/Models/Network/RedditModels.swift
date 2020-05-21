import Foundation

struct Subreddit: RedditResponsable, Identifiable {
	let id: String
	let name: String

	init(json: [String: Any]) {
		let data = json["data"] as! [String: Any]
		id = data["id"] as! String
		name = data["display_name"] as! String
	}
}

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
