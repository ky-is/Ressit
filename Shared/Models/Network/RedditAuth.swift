import AuthenticationServices
import Combine

final class RedditAuthModel: ObservableObject {
	static let shared = RedditAuthModel()

	@Published var accessToken = UserDefaults.standard.string(forKey: "access_token")
	@Published var loading = false

	func toggleLoading(_ loading: Bool) {
		DispatchQueue.main.async {
			self.loading = loading
		}
	}
}

struct RedditAuthResponse: Decodable {
	let accessToken: String
	let refreshToken: String?
	let expiresIn: TimeInterval

	enum CodingKeys: String, CodingKey {
		case accessToken, refreshToken, expiresIn
	}
}

struct RedditAuthManager {
	private static let clientID = "sBrY48PRjJuRRQ"
	private static let uuid = UUID().uuidString
	private static let redirectURI = "ressit://auth"
	private static var authURL: URL {
		let baseURL = URL(string: "https://www.reddit.com/api/v1/authorize.compact")!
		let scopes = ["read", "mysubreddits", "save", "vote"]
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
	private static let accessTokenURL = URL(string: "https://www.reddit.com/api/v1/access_token")!

	static private var authProvider = AuthenticationWindowProvider()
	static private var refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
	static private var refreshExpireDuration: TimeInterval = UserDefaults.standard.double(forKey: "expires_in")
	static private var refreshExpiresAt: Date {
		Date().addingTimeInterval(refreshExpireDuration)
	}

	static private var authorizationPublisher: AnyPublisher<RedditAuthResponse, Error>?
	static private var authorizationSubscription: AnyCancellable?
	static private var authorizationBody: Data?

	enum GrantType: String {
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
					URLQueryItem(name: "redirect_uri", value: redirectURI),
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
			refreshIfNeeded()
			return
		}
		createSignin()
	}

	@discardableResult private static func createSignin() -> AnyPublisher<RedditAuthResponse, Error> {
		let future = Future<RedditAuthResponse, Error> { promise in
			let webAuthenticationSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: redirectURI) { url, error in
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
				guard oauthStateComponent.value == uuid else {
					return print("Invalid state", oauthStateComponent)
				}
				createAuthorization(grantType: .code, token: oauthToken, promise: promise)
			}
			webAuthenticationSession.presentationContextProvider = authProvider
			webAuthenticationSession.start()
		}
		return future.eraseToAnyPublisher()
	}

	private static func isRefreshTokenValid() -> Bool {
		guard refreshToken != nil else {
			return false
		}
		let timeIntervalUntilRefreshRequired = Date().distance(to: refreshExpiresAt)
		return timeIntervalUntilRefreshRequired > refreshExpireDuration / 4
	}

	static func reauthorize() -> AnyPublisher<RedditAuthResponse, Error> {
		guard refreshToken != nil else {
			return createSignin()
		}
		return createRefresh()

	}

	static func refreshIfNeeded() {
		if let refreshToken = refreshToken, !isRefreshTokenValid() {
			createAuthorization(grantType: .refresh, token: refreshToken)
		}
	}

	static private func createRefresh() -> AnyPublisher<RedditAuthResponse, Error> {
		return createAuthorization(grantType: .refresh, token: refreshToken)
	}

	static func authorizeAnonymously() {
		createAuthorization(grantType: .anonymous)
	}

	private static let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()

	@discardableResult static func createAuthorization(grantType: GrantType, token: String? = nil, promise: ((Result<RedditAuthResponse, Error>) -> Void)? = nil) -> AnyPublisher<RedditAuthResponse, Error> {
		let queryItems = grantType.getQueryItems(with: token)
		var components = URLComponents()
		components.queryItems = queryItems
		let newAuthorizationBody = components.query!.data(using: .utf8)
		if let authorizationPublisher = authorizationPublisher, let oldAuthorizationBody = authorizationBody, newAuthorizationBody == oldAuthorizationBody {
			return authorizationPublisher
		}
		authorizationSubscription?.cancel()
		var request = URLRequest(url: accessTokenURL)
		authorizationBody = newAuthorizationBody
		request.httpBody = newAuthorizationBody
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		let encodedClientIDAndEmptyPassword = "\(clientID):".data(using: .utf8)!.base64EncodedString()
		request.addValue("Basic \(encodedClientIDAndEmptyPassword)", forHTTPHeaderField: "Authorization")

		RedditAuthModel.shared.toggleLoading(true)
		let authorizationPublisher = URLSession.shared.dataTaskPublisher(for: request)
			.tryMap { data, response in
				let httpResponse = response as! HTTPURLResponse
				guard httpResponse.statusCode == 200 else {
					throw APIError.status(code: httpResponse.statusCode)
				}
				return data
			}
			.decode(type: RedditAuthResponse.self, decoder: decoder)
			.eraseToAnyPublisher()
		self.authorizationPublisher = authorizationPublisher
		authorizationSubscription = authorizationPublisher
			.sink(receiveCompletion: { completion in
				RedditAuthModel.shared.toggleLoading(false)
				authorizationBody = nil
				switch completion {
				case .failure(let error):
					promise?(.failure(error))
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
				defaults.set(response.accessToken, forKey: "access_token")
				defaults.set(response.refreshToken, forKey: "refresh_token")
				defaults.set(response.expiresIn, forKey: "expires_in")
				defaults.synchronize()
				promise?(.success(response))
			}
		return authorizationPublisher
	}
}

private final class AuthenticationWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return globalPresentationAnchor ?? ASPresentationAnchor()
	}
}
