import Foundation

struct RedditSubreddit: RedditResponsable, RedditIdentifiable {
	static let type = "t5"

	let id: String
	let name: String
	let subscribers: String

	init?(json: Any) {
		let data = Self.defaultJSONData(json)
		guard let subscribers = data["subscribers"] as? Int else {
			return nil
		}
		id = data["id"] as! String
		name = data["display_name"] as! String
		self.subscribers = subscribers.estimatedDescription
	}
}
