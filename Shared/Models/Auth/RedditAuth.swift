import AuthenticationServices

struct RedditAuth {
	static private var authSession: ASWebAuthenticationSession?
	static private var authProvider = AuthenticationWindowProvider()
	static private var refreshToken: String?
	static private var refreshExpireDuration: TimeInterval = 60 * 60
	static private var refreshExpiresAt = Date()

	static func login() {
		if authSession != nil {
			authSession?.cancel()
			authSession = nil
		}
		authSession = ASWebAuthenticationSession(url: RedditConfig.authURL, callbackURLScheme: RedditConfig.redirectURI) { (url, error) in
			if let error = error {
				return print(error)
			}
			guard let url = url else {
				return
			}
			guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
				return print("Invalid URL", url)
			}
			guard let oauthToken = queryItems.first(where: { $0.name == "code" })?.value, let oauthStateComponent = queryItems.first(where: { $0.name == "state" }) else {
				return print("Invalid URL query", queryItems)
			}
			guard oauthStateComponent.value == RedditConfig.uuid else {
				return print("Invalid state", oauthStateComponent)
			}
			print(oauthToken, queryItems)
		}
		authSession?.presentationContextProvider = authProvider
		authSession?.start()
	}

	static func refreshIfNeeded() {
		guard let refreshToken = refreshToken else {
			return
		}
		let timeIntervalUntilRefreshRequired = -refreshExpiresAt.distance(to: Date())
		if timeIntervalUntilRefreshRequired < refreshExpireDuration / 2 {
			authorize(grantType: "refresh_token", refreshToken: refreshToken)
		}
	}

	static func anonymous() {
		authorize(grantType: "https://oauth.reddit.com/grants/installed_client")
	}

	private static func authorize(grantType: String, refreshToken: String? = nil) {
		let url = URL(string: "https://www.reddit.com/api/v1/access_token")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		let encodedClientIDAndPassword = "\(RedditConfig.clientID):".data(using: .utf8)!.base64EncodedString()
		request.addValue("Basic \(encodedClientIDAndPassword)", forHTTPHeaderField: "Authorization")

		let grantTypeQuery = URLQueryItem(name: "grant_type", value: grantType)
		let deviceIDQuery = URLQueryItem(name: "device_id", value: "DO_NOT_TRACK_THIS_DEVICE")
		let refreshTokenQuery = URLQueryItem(name: "refresh_token", value: refreshToken)
		var components = URLComponents()
		components.queryItems = [grantTypeQuery, deviceIDQuery, refreshTokenQuery]
		request.httpBody = components.query!.data(using: .utf8)

		let session = URLSession(configuration: URLSessionConfiguration.default)
		let startDate = Date()
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				return print(error)
			}
			guard let data = data else {
				return print("No data")
			}
			do {
				let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
				if let json = json as? [String: Any], let token = json["access_token"] as? String {
					if let expiresIn = json["expires_in"] as? TimeInterval {
						refreshExpireDuration = expiresIn
						refreshExpiresAt = startDate.advanced(by: expiresIn)
					}
					print(token)
				} else {
					print("Invalid JSON", json)
				}
			} catch {
				print(error)
			}
		}
		task.resume()
	}
}

private final class AuthenticationWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {

	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return globalPresentationAnchor ?? ASPresentationAnchor()
	}

}
