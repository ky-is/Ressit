import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostView: View {
	let post: SubredditPostModel?

	var body: some View {
		Group {
			if post != nil {
				SubredditPostContainer(post: post!)
			} else {
				EmptyView()
			}
		}
			.onDisappear {
				PostUserModel.shared.selected = nil
			}
	}
}

private struct SubredditPostContainer: View {
	let post: SubredditPostModel
	private let commentsViewModel: SubredditPostCommentsViewModel

	init(post: SubredditPostModel) {
		self.post = post
		if let latest = SubredditPostCommentsViewModel.latest, latest.id == post.id {
			self.commentsViewModel = latest
		} else {
			self.commentsViewModel = SubredditPostCommentsViewModel(post: post)
		}
	}

	var body: some View {
		ScrollView {
			SubredditPostHeader(post: post)
			SubredditPostBody(post: post, commentsViewModel: commentsViewModel)
		}
	}
}

private struct SubredditPostHeader: View {
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
					Text(post.creationDate.relativeToNow)
				}
				SubredditTitle(name: post.subreddit.name)
				Spacer()
			}
				.font(.caption)
		}
			.fixedSize(horizontal: false, vertical: true)
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
