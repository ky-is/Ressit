import SwiftUI

struct SubredditPostListEntry: View {
	let post: UserPost
	let hasSubredditContext: Bool

	var body: some View {
		SubredditPostButton(post: post, hasSubredditContext: hasSubredditContext)
			.modifier(PostEnabledModifier(post: post))
			.modifier(PostListRowSwipeModifier(post: post))
	}
}

private struct PostEnabledModifier: ViewModifier {
	@ObservedObject var post: UserPost

	func body(content: Content) -> some View {
		content
			.opacity(post.metadata?.readDate != nil ? 2/3 : 1)
	}
}

private struct SubredditPostButton: View {
	let post: UserPost
	let hasSubredditContext: Bool

	var body: some View {
		Button(action: {
			PostUserModel.shared.selected = self.post
		}) {
			HStack(alignment: .top) {
				if post.thumbnail != nil {
					ImageDownloadView(viewModel: post.getThumbnailManager()!)
						.frame(width: 80, height: 80)
						.clipped()
						.cornerRadius(2)
				}
				VStack(alignment: .leading, spacing: 4) {
					VStack(alignment: .leading) {
						Text(post.title)
							.font(.headline)
						if !hasSubredditContext {
							SubredditTitle(name: post.subreddit.name)
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
					}
					HStack {
						ScoreMetadata(entity: post)
						CommentsMetadata(post: post)
						RelativeIcon(since: post.creationDate)
						AwardsMetadata(entity: post)
						SavedMetadata(entity: post)
					}
						.font(Font.caption.monospacedDigit())
				}
					.padding(.vertical, 6)
			}
		}
	}
}

struct SubredditPostListEntry_Previews: PreviewProvider {
	private static let context = CoreDataModel().persistentContainer.viewContext
	private static var post: UserPost = {
		let post = UserPost(context: context)
		post.title = "Test"
		post.score = 42
		post.commentCount = 8001
		post.creationDate = Date(timeIntervalSinceReferenceDate: 0)
		return post
	}()

	static var previews: some View {
		List {
			SubredditPostListEntry(post: post, hasSubredditContext: false)
		}
			.environment(\.managedObjectContext, context)
	}
}
