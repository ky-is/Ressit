import Foundation
import Combine

enum APIError: Error, Equatable {
	case uninitialized
	case invalidJSON
	case status(code: Int)
	case unauthorized
}

enum HTTPMethod: String {
	case get, post, put, delete
}

final class RedditClient {
	static let shared = RedditClient()

	private let baseUrl = URL(string: "https://oauth.reddit.com")!

	func send<Result: RedditResponsable>(_ apiRequest: APIRequest<Result>) -> AnyPublisher<Result, Error> {
		guard let accessToken = RedditAuthModel.shared.accessToken else {
			return Fail(error: APIError.uninitialized).eraseToAnyPublisher()
		}
		return URLSession.shared
			.dataTaskPublisher(for: self.transform(accessToken: accessToken, apiRequest: apiRequest))
			.tryMap { try self.transform($0.data, $0.response) }
			.tryCatch { error -> AnyPublisher<Result, Error> in
				guard let apiError = error as? APIError, apiError == .unauthorized else {
					throw error
				}
				return RedditAuthManager.reauthorize()
					.flatMap { _ in self.send(apiRequest) }
					.eraseToAnyPublisher()
			}
			.eraseToAnyPublisher()
	}

	private func transform<Result: RedditResponsable>(accessToken: String, apiRequest: APIRequest<Result>) -> URLRequest {
		let url = baseUrl.appendingPathComponent(apiRequest.path)
		var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
		components.queryItems = apiRequest.parameters?.map { (key, value) in URLQueryItem(name: key, value: value) }
		components.queryItems?.append(URLQueryItem(name: "raw_json", value: "1"))
		var request = URLRequest(url: components.url!)
		request.httpMethod = apiRequest.method?.rawValue
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
//		print(String(data: data, encoding: .utf8)!) //SAMPLE
		let json = try JSONSerialization.jsonObject(with: data, options: [])
		return Result(json: json)!
	}
}

final class APIRequest<Result> {
	let path: String
	let parameters: [String: String]?
	let method: HTTPMethod?

	init(path: String, parameters: [String: String]? = nil, method: HTTPMethod? = nil) {
		self.path = path
		self.parameters = parameters
		self.method = method
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
	static func comments(for post: SubredditPostModel) -> APIRequest<RedditPostComments> {
		APIRequest<RedditPostComments>(path: "/r/\(post.subreddit.name)/comments/\(post.id)", parameters: ["article": post.id, "sort": "top"])
	}
	static func save<Entity: RedditIdentifiable>(entity: Entity, enabled: Bool) -> APIRequest<EmptyReddit> {
		APIRequest<EmptyReddit>(path: "/api/\(enabled ? "save" : "unsave")", parameters: ["id": entity.fullName()], method: .post)
	}
	static func vote<Entity: RedditIdentifiable>(entity: Entity, vote: Int) -> APIRequest<EmptyReddit> {
		APIRequest<EmptyReddit>(path: "/api/vote", parameters: ["id": entity.fullName(), "dir": vote.description], method: .post)
	}
}
