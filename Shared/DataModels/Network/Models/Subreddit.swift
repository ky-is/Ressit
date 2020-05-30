import Foundation

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
