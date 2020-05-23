import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostView: View {
	@ObservedObject var post: SubredditPostModel

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(post.title)
				.font(.headline)
			HStack {
				HStack(spacing: 1) {
					Text("👤")
					Text(post.author)
				}
				HStack(spacing: 1) {
					Text("🗓")
					Text(post.creationString)
				}
				SubredditTitle(name: post.subreddit.name)
				Spacer()
			}
				.font(.caption)
			Spacer()
		}
			.padding()
			.navigationBarTitle(Text(post.title), displayMode: .inline)
	}
}

struct SubredditPostView_Previews: PreviewProvider {
	static var previews: some View {
		let post = SubredditPostModel(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.author = "Tester"
		post.commentCount = 42
		post.creationDate = Date(timeIntervalSinceNow: -.month)
		return NavigationView {
			SubredditPostView(post: post)
		}
	}
}
