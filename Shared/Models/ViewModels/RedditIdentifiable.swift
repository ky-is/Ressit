protocol RedditIdentifiable: Identifiable {
	var id: String { get }
	static var type: String { get }

	func fullName() -> String
}

extension RedditIdentifiable {
	func fullName() -> String {
		return "\(Self.type)_\(id)"
	}
}
