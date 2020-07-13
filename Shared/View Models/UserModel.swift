import Combine
import SwiftUI

final class SubredditUserModel: ObservableObject {
	static let shared = SubredditUserModel()

	@Published var selected: SubredditPostsViewModel? {
		didSet {
			isActive = selected != nil
		}
	}

	@Published private(set) var isActive = false
}

final class PostUserModel: ObservableObject {
	static let shared = PostUserModel()

	@Published var selected: UserPost? {
		didSet {
			isActive = selected != nil
		}
	}

	@Published private(set) var isActive = false

	func performDelete() {
		selected = nil
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let readRequest = UserPost.fetchRequest()
		readRequest.predicate = \UserPost.metadata?.readDate != nil
		do {
			let readPosts = try context.fetch(readRequest) as! [UserPost]
			context.perform {
				let allSubreddits = readPosts.map(\.subreddit)
				readPosts.forEach(context.delete)
				context.safeSave()
				Set(allSubreddits).forEach { context.refresh($0, mergeChanges: true) }
			}
		} catch {
			print(error)
		}
	}
}
