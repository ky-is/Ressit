import Foundation

final class SubredditPostComment: RedditResponsable, RedditVotable {
	static let type = "t1"

	let id: String
	let author: String?
	let body: String?
	let creationDate: Date?
	let editedAt: TimeInterval?
	let score: Int
	let replies: RedditListing<SubredditPostComment>?
	let childIDs: [String]?

	@Published var userVote: Int

	init?(json: Any) {
		let data = Self.defaultJSONData(json)

		let created = data["created"] as? TimeInterval
		let creationDate = created != nil ? Date(timeIntervalSince1970: created!) : nil
		self.creationDate = creationDate

		let childIDs = data["children"] as? [String]
		if childIDs?.isEmpty ?? false {
			if creationDate != nil {
				print("INVALID CHILDREN", data)
			}
			return nil
		}
		self.childIDs = childIDs

		let author = data["author"] as? String
		if let rawReplies = data["replies"] as? [String: Any] {
			replies = RedditListing<SubredditPostComment>(json: rawReplies)
		} else {
			replies = nil
		}
		if replies?.values.nonEmpty == nil && (author == nil || author == "[deleted]") { //TODO && childIDs == nil, if we want to be able to load replies to deleted posts
			return nil
		}
		self.author = author

		id = data["id"] as! String
		body = data["body"] as? String
		let editTimestamp = data["edited"] as? TimeInterval ?? 0
		editedAt = editTimestamp > 0 ? editTimestamp : nil
		score = data["score"] as? Int ?? 0
		let likes = data["likes"] as? Bool
		userVote = likes == true ? 1 : (likes == false ? -1 : 0)
	}

	var deleted: Bool {
		author == nil || author == "[deleted]"
	}
}
