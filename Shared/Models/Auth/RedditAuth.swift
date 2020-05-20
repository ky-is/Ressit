import AuthenticationServices
import Combine

final class RedditAuthModel: ObservableObject {
	static let shared = RedditAuthModel()

	@Published var accessToken = UserDefaults.standard.string(forKey: "access_token")
	@Published var loading = false
}

private struct RedditAuthResponse: Decodable {
	let accessToken: String
	let refreshToken: String?
	let expiresIn: TimeInterval

	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
		case expiresIn = "expires_in"
	}
}

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
	static let accessTokenURL = URL(string: "https://www.reddit.com/api/v1/access_token")!
}

struct RedditAuthManager {
	static private var authProvider = AuthenticationWindowProvider()
	static private var refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
	static private var refreshExpireDuration: TimeInterval = UserDefaults.standard.double(forKey: "expires_in")
	static private var refreshExpiresAt: Date {
		Date().addingTimeInterval(refreshExpireDuration)
	}

	static private var authSession: ASWebAuthenticationSession?
	static private var authorization: AnyCancellable?

	private enum GrantType: String {
		case anonymous = "https://oauth.reddit.com/grants/installed_client"
		case code = "authorization_code"
		case refresh = "refresh_token"

		func getQueryItems(with token: String?) -> [URLQueryItem] {
			let items = [URLQueryItem(name: "grant_type", value: rawValue)]
			switch self {
			case .anonymous:
				return items + [
					URLQueryItem(name: "device_id", value: "DO_NOT_TRACK_THIS_DEVICE"),
				]
			case .code:
				return items + [
					URLQueryItem(name: "code", value: token),
					URLQueryItem(name: "redirect_uri", value: RedditConfig.redirectURI),
				]
			case .refresh:
				return items + [
					URLQueryItem(name: "refresh_token", value: token),
				]
			}
		}
	}

	static var authorized: Future<Bool, Never> {
		return Future { promise in
			promise(.success(true))
		}
	}

	private static func canRefresh() -> Bool {
		return RedditAuthModel.shared.accessToken != nil && refreshToken != nil
	}

	static func signinIfNeeded() {
		if canRefresh() {
			return refreshIfNeeded()
		}
		let authSession = ASWebAuthenticationSession(url: RedditConfig.authURL, callbackURLScheme: RedditConfig.redirectURI) { url, error in
			if let error = error {
				return print(#function, error.localizedDescription)
			}
			guard let url = url else {
				return
			}
			guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
				return print("Invalid URL", url)
			}
			guard let oauthToken = queryItems.first(where: { $0.name == "code" })?.value, let oauthStateComponent = queryItems.first(where: { $0.name == "state" }) else {
				if let error = queryItems.first(where: { $0.name == "error" })?.value {
					return print(error)
				}
				return print("Invalid URL query", queryItems)
			}
			guard oauthStateComponent.value == RedditConfig.uuid else {
				return print("Invalid state", oauthStateComponent)
			}
			authorize(grantType: .code, token: oauthToken)
		}
		authSession.presentationContextProvider = authProvider
		authSession.start()
	}

	private static func isRefreshTokenValid() -> Bool {
		guard refreshToken != nil else {
			return false
		}
		let timeIntervalUntilRefreshRequired = Date().distance(to: refreshExpiresAt)
		return timeIntervalUntilRefreshRequired > refreshExpireDuration / 4
	}

	static func refreshIfNeeded() {
		if let refreshToken = refreshToken, !isRefreshTokenValid() {
			authorize(grantType: .refresh, token: refreshToken)
		}
	}

	static func authorizeAnonymously() {
		authorize(grantType: .anonymous)
	}

	private static let decoder = JSONDecoder()

	private static func authorize(grantType: GrantType, token: String? = nil) {
		RedditAuthModel.shared.loading = true

		var request = URLRequest(url: RedditConfig.accessTokenURL)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		let encodedClientIDAndEmptyPassword = "\(RedditConfig.clientID):".data(using: .utf8)!.base64EncodedString()
		request.addValue("Basic \(encodedClientIDAndEmptyPassword)", forHTTPHeaderField: "Authorization")

		let queryItems = grantType.getQueryItems(with: token)
		var components = URLComponents()
		components.queryItems = queryItems
		request.httpBody = components.query!.data(using: .utf8)

		authorization?.cancel()
		authorization = URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response in
				let httpResponse = response as! HTTPURLResponse
				guard httpResponse.statusCode == 200 else {
					throw APIError.status(code: httpResponse.statusCode)
				}
				return data
			}
			.decode(type: RedditAuthResponse.self, decoder: decoder)
			.sink(receiveCompletion: { completion in
				DispatchQueue.main.async {
					RedditAuthModel.shared.loading = false
				}
				switch completion {
				case .failure(let error):
					print(#function, error)
				case .finished:
					break
				}
			}) { response in
				DispatchQueue.main.async {
					RedditAuthModel.shared.accessToken = response.accessToken
				}
				refreshToken = response.refreshToken
				refreshExpireDuration = response.expiresIn

				let defaults = UserDefaults.standard
				defaults.set(RedditAuthModel.shared.accessToken, forKey: "access_token")
				defaults.set(refreshToken, forKey: "refresh_token")
				defaults.set(refreshExpireDuration, forKey: "expires_in")
				defaults.synchronize()
			}
	}
}

private final class AuthenticationWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return globalPresentationAnchor ?? ASPresentationAnchor()
	}
}
