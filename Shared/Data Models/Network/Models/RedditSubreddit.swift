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
		self.id = data["id"] as! String
		self.name = data["display_name"] as! String
		self.subscribers = subscribers.estimatedDescription
	}
}
