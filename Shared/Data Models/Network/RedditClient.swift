import Foundation
import Combine

enum APIError: Error, Equatable {
	case uninitialized
	case invalidJSON
	case status(code: Int)
	case unauthorized
	case rateLimited(interval: TimeInterval)
}

enum HTTPMethod: String {
	case get, post, put, delete
}

extension Publisher {
	func retry<T, E>(after interval: TimeInterval) -> Publishers.Catch<Self, AnyPublisher<T, E>> where T == Self.Output, E == Self.Failure {
		return self.catch { error -> AnyPublisher<T, E> in
			return Publishers.Delay(upstream: self, interval: .seconds(interval), tolerance: 1, scheduler: RunLoop.current)
				.retry(2)
				.eraseToAnyPublisher()
		}
	}
}

final class RedditClient {
	static let shared = RedditClient()

	private let baseUrl = URL(string: "https://oauth.reddit.com")!

	static var rateLimitEnds: Date?

	private func retry<Result: RedditResponsable>(_ apiRequest: APIRequest<Result>, after interval: TimeInterval) -> AnyPublisher<Result, Error> {
		return Just<Result?>(nil)
			.delay(for: .seconds(interval), scheduler: RunLoop.current)
			.mapError { error in APIError.uninitialized as Error }
			.flatMap { _ in self.send(apiRequest) }
			.eraseToAnyPublisher()
	}

	func send<Result: RedditResponsable>(_ apiRequest: APIRequest<Result>) -> AnyPublisher<Result, Error> {
		guard let accessToken = RedditAuthModel.shared.accessToken else {
			return Fail(error: APIError.uninitialized).eraseToAnyPublisher()
		}
		if let rateLimitEnds = Self.rateLimitEnds {
			let rateLimitInterval = rateLimitEnds.timeIntervalSinceNow
			if rateLimitInterval > 1 {
				return retry(apiRequest, after: rateLimitInterval)
			}
		}
		return URLSession.shared.dataTaskPublisher(for: transform(accessToken: accessToken, apiRequest: apiRequest))
			.tryMap { try self.transform($0.data, $0.response) }
			.tryCatch { error -> AnyPublisher<Result, Error> in
				guard let apiError = error as? APIError else {
					throw error
				}
				switch apiError {
				case .unauthorized:
					return RedditAuthManager.reauthorize()
						.flatMap { _ in self.send(apiRequest) }
						.eraseToAnyPublisher()
				case .rateLimited(let interval):
					Self.rateLimitEnds = Date(timeIntervalSinceNow: interval)
					return self.retry(apiRequest, after: interval)
				default:
					throw error
				}
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
		if statusCode == 429 {
			if let remainingHeader = httpResponse.value(forHTTPHeaderField: "x-ratelimit-remaining"), let remainingCount = Double(remainingHeader) {
				if remainingCount > 1 {
					throw APIError.rateLimited(interval: 9)
				}
				if let resetHeader = httpResponse.value(forHTTPHeaderField: "x-ratelimit-reset"), let resetAfterSeconds = TimeInterval(resetHeader) {
					throw APIError.rateLimited(interval: resetAfterSeconds)
				}
			}
			print("Unknown rate limit", httpResponse.value(forHTTPHeaderField: "x-ratelimit-used") ?? "", httpResponse.value(forHTTPHeaderField: "x-ratelimit-remaining") ?? "", httpResponse.value(forHTTPHeaderField: "x-ratelimit-reset") ?? "", httpResponse.allHeaderFields)
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
	static var subredditsMine: APIRequest<RedditListing<RedditSubreddit>> {
		APIRequest<RedditListing<RedditSubreddit>>(path: "/subreddits/mine", parameters: ["limit": "100"])
	}
	static func subreddits(search query: String) -> APIRequest<RedditListing<RedditSubreddit>> {
		APIRequest<RedditListing<RedditSubreddit>>(path: "/subreddits/search", parameters: ["q": query])
	}
	static func topPosts(in subreddit: String, over period: RedditPeriod, count: Int) -> APIRequest<RedditListing<RedditPost>> {
		APIRequest<RedditListing<RedditPost>>(path: "/r/\(subreddit)/top", parameters: ["t": period.rawValue, "limit": count.description])
	}
	static func comments(for post: UserPost) -> APIRequest<RedditPostComments> {
		APIRequest<RedditPostComments>(path: "/r/\(post.subreddit.name)/comments/\(post.id)", parameters: ["article": post.id, "sort": "top"])
	}
	static func save<Entity: RedditIdentifiable>(entity: Entity, enabled: Bool) -> APIRequest<EmptyReddit> {
		APIRequest<EmptyReddit>(path: "/api/\(enabled ? "save" : "unsave")", parameters: ["id": entity.fullName()], method: .post)
	}
	static func vote<Entity: RedditIdentifiable>(entity: Entity, vote: Int) -> APIRequest<EmptyReddit> {
		APIRequest<EmptyReddit>(path: "/api/vote", parameters: ["id": entity.fullName(), "dir": vote.description], method: .post)
	}
}
