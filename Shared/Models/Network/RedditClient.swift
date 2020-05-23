import Foundation
import Combine

protocol RedditResponsable {
	init(json: [String: Any])
}

final class RedditClient {
	static let shared = RedditClient()

	private let baseUrl = URL(string: "https://oauth.reddit.com")!

	func send<Result: RedditResponsable>(_ request: APIRequest<Result>) -> AnyPublisher<Result, Error> {
		guard let accessToken = RedditAuthModel.shared.accessToken else {
			return Fail(error: APIError.uninitialized).eraseToAnyPublisher()
		}
		return URLSession.shared
			.dataTaskPublisher(for: self.transform(accessToken: accessToken, request: request))
			.tryMap { try self.transform($0.data, $0.response) }
			.tryCatch { error -> AnyPublisher<Result, Error> in
				guard let apiError = error as? APIError, apiError == .unauthorized else {
					throw error
				}
				return RedditAuthManager.reauthorize()
					.flatMap { _ in self.send(request) }
					.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}

	private func transform<Result: RedditResponsable>(accessToken: String, request: APIRequest<Result>) -> URLRequest {
		let url = baseUrl.appendingPathComponent(request.path)
		var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
		components.queryItems = request.parameters?.map { (key, value) in URLQueryItem(name: key, value: value) }
		components.queryItems?.append(URLQueryItem(name: "raw_json", value: "1"))
		var request = URLRequest(url: components.url!)
		request.addValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		return request
	}

	private func transform<Result: RedditResponsable>(_ data: Data, _ response: URLResponse) throws -> Result {
		let httpResponse = response as! HTTPURLResponse
		let statusCode = httpResponse.statusCode
		if statusCode == 401 {
			throw APIError.unauthorized
		}
		guard statusCode == 200 else {
			throw APIError.status(code: statusCode)
		}
		let rawJSON = try JSONSerialization.jsonObject(with: data, options: [])
		guard let baseJSON = rawJSON as? [String: Any], let jsonContents = baseJSON["data"] as? [String: Any] else {
			throw APIError.invalidJSON
		}
		return Result(json: jsonContents)
	}
}

enum APIError: Error, Equatable {
	case uninitialized
	case invalidJSON
	case status(code: Int)
	case unauthorized
}

final class APIRequest<Result> {
	let path: String
	let parameters: [String: String]?

	init(path: String, parameters: [String: String]? = nil) {
		self.path = path
		self.parameters = parameters
	}
}

extension APIRequest {
	static var subredditsMine: APIRequest<RedditListing<Subreddit>> {
		APIRequest<RedditListing<Subreddit>>(path: "/subreddits/mine", parameters: ["limit": "100"])
	}
	static func subreddits(search query: String) -> APIRequest<RedditListing<Subreddit>> {
		APIRequest<RedditListing<Subreddit>>(path: "/subreddits/search", parameters: ["q": query])
	}
	static func topPosts(in subreddit: String, over period: RedditPeriod, count: Int) -> APIRequest<RedditListing<SubredditPost>> {
		APIRequest<RedditListing<SubredditPost>>(path: "/r/\(subreddit)/top", parameters: ["t": period.rawValue, "limit": count.description])
	}
	static func comments(for post: SubredditPostModel) -> APIRequest<RedditListing<SubredditPostComment>> {
		APIRequest<RedditListing<SubredditPostComment>>(path: "/r/\(post.subreddit.name)/comments", parameters: ["article": post.id, "sort": "top"])
	}
}
