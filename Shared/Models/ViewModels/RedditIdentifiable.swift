import SwiftUI

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

protocol RedditVotable: RedditIdentifiable, ObservableObject {
	var userVote: Int { get }
	var score: Int { get }

	func voteColor() -> Color
}

extension RedditVotable {
	func voteColor() -> Color {
		if userVote > 0 {
			return .orange
		}
		if userVote < 0 {
			return .blue
		}
		return .secondary
	}
}
