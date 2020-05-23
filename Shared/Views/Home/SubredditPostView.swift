import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostView: View {
	@ObservedObject var post: SubredditPostModel

	private let commentsViewModel: SubredditPostCommentsViewModel

	init(post: SubredditPostModel) {
		self.post = post
		commentsViewModel = SubredditPostCommentsViewModel(post: post)
	}

	var body: some View {
		ScrollView {
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
						Text(post.creationDate.relativeToNow)
					}
					SubredditTitle(name: post.subreddit.name)
					Spacer()
				}
					.font(.caption)
			}
				.padding()
			RedditView(commentsViewModel) { result in
				VStack(alignment: .leading) {
					ForEach(result.values) { comment in
						Divider()
						VStack(alignment: .leading) {
							Text(comment.text)
							HStack {
								Text(comment.author)
								Text(comment.creationDate.relativeToNow)
							}
							.font(.caption)
						}
							.padding(.horizontal)
					}
				}
			}
		}
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
