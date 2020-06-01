import SwiftUI

struct SubredditPostListEntry: View {
	let post: UserPost

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		SubredditPostButton(post: post)
			.modifier(PostEnabledModifier(post: post))
			.modifier(
				ListRowSwipeModifier(
					leading: [
						SwipeSegment(primary: .upvote, reset: .upvoteRemove, shouldReset: { self.post.userVote > 0 }) { action in
							self.post.toggleVote(action == .upvote ? 1 : 0, in: self.context)
						},
						SwipeSegment(primary: .downvote, reset: .downvoteRemove, shouldReset: { self.post.userVote < 0 }) { action in
							self.post.toggleVote(action == .downvote ? -1 : 0, in: self.context)
						},
					],
					trailing: [
						SwipeSegment(primary: .markRead, reset: .markUnread, shouldReset: { self.post.metadata?.readDate != nil }) { action in
							self.post.performRead(action == .markRead, in: self.context)
						},
						SwipeSegment(primary: .save, reset: .unsave, shouldReset: { self.post.userSaved }) { action in
							self.post.performSaved(action == .save, in: self.context)
						},
					]
				)
			)
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
					Text(post.title)
						.font(.headline)
					HStack {
						ScoreMetadata(entity: post)
						IconText(iconName: "bubble.left.and.bubble.right", label: post.commentCount.description)
						IconText(iconName: "clock", label: post.creationDate?.relativeToNow ?? "")
						SaveadMetadata(entity: post)
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
			SubredditPostListEntry(post: post)
		}
			.environment(\.managedObjectContext, context)
	}
}
