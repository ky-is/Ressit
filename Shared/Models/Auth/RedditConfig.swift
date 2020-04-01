import Foundation

struct RedditConfig {
	static let clientID = "sBrY48PRjJuRRQ"
	static let uuid = UUID().uuidString
	static let redirectURI = "reddss://auth"
	static var authURL: URL {
		let baseURL = URL(string: "https://www.reddit.com/api/v1/authorize.compact")!
		let scopes = ["mysubreddits", "save", "vote"]
		var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
		urlComponents.queryItems = [
			URLQueryItem(name: "client_id", value: clientID),
			URLQueryItem(name: "response_type", value: "code"),
			URLQueryItem(name: "state", value: uuid),
			URLQueryItem(name: "redirect_uri", value: redirectURI),
			URLQueryItem(name: "duration", value: "permanent"),
			URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
		]
		return urlComponents.url!
	}
	static let anonymousURL = "https://www.reddit.com/api/v1/access_token"
}
