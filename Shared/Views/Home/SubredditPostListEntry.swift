import SwiftUI

struct SubredditPostListEntry: View {
	let post: SubredditPostModel

	var body: some View {
		Button(action: {
			PostUserModel.shared.selected = self.post
		}) {
			VStack(alignment: .leading, spacing: 4) {
				Text(post.title)
					.font(.headline)
				HStack {
					Text("🔺") + Text(post.score.description)
					Text("💬") + Text(post.commentCount.description)
					Text("🕓") + Text(post.creationDate.relativeToNow)
				}
					.font(.caption)
			}
				.padding(.vertical, 6)
		}
	}
}

struct SubredditPostListEntry_Previews: PreviewProvider {
	static var previews: some View {
		let post = SubredditPostModel(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.score = 42
		post.commentCount = 8001
		post.creationDate = Date(timeIntervalSinceReferenceDate: 0)
		return SubredditPostListEntry(post: post)
	}
}
