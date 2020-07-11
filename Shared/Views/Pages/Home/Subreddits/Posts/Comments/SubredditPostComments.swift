import SwiftUI

struct SubredditPostComments: View {
	let post: UserPost
	let commentsViewModel: SubredditPostCommentsViewModel
	let width: CGFloat

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		RedditView(commentsViewModel, loadingHeight: 128) { postComments in
			SubredditPostCommentsContainer(userPost: post, postComments: postComments, width: width)
		}
	}
}

private struct SubredditPostCommentsContainer: View {
	let comments: RedditListing<RedditComment>
	let width: CGFloat

	init(userPost: UserPost, postComments: RedditPostComments, width: CGFloat) {
		self.comments = postComments.comments
		self.width = width
		userPost.update(fromRemote: postComments.post, in: CoreDataModel.shared.persistentContainer.viewContext)
	}

	var body: some View {
		Group {
			if comments.values.isEmpty {
				Text("No comments yet...")
					.font(.subheadline)
					.foregroundColor(.secondary)
					.padding()
			} else {
				SubredditPostCommentGroup(comments: comments, maxDepth: 20, currentDepth: 0, width: width)
			}
		}
	}
}

private struct SubredditPostCommentGroup: View {
	let comments: RedditListing<RedditComment>
	let maxDepth: Int
	let currentDepth: Int
	let width: CGFloat

	var body: some View {
		ForEach(comments.values) { comment in
			SubredditPostCommentTree(comment: comment, maxDepth: maxDepth, currentDepth: currentDepth, width: width)
		}
			.listRowInsets(.zero)
	}
}

private let insets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)

private struct SubredditPostCommentTree: View {
	let comment: RedditComment
	let maxDepth: Int
	let currentDepth: Int
	let width: CGFloat
	private let isRoot: Bool

	@State private var collapsed = false

	init(comment: RedditComment, maxDepth: Int, currentDepth: Int, width: CGFloat) {
		self.comment = comment
		self.maxDepth = maxDepth
		self.currentDepth = currentDepth
		self._collapsed = State(initialValue: comment.deleted)
		self.width = width
		self.isRoot = currentDepth == 0
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			Divider()
				.background(isRoot ? Color.secondary : nil)
				.padding(.leading, isRoot ? 16 - insets.leading : 0)
			SubredditPostCommentContent(comment: comment, currentDepth: currentDepth, collapsed: $collapsed, width: width)
				.onTapGesture {
					if comment.childIDs == nil {
						withAnimation {
							collapsed.toggle()
						}
					}
				}
			if !collapsed && comment.replies != nil && currentDepth < maxDepth {
				SubredditPostCommentGroup(comments: comment.replies!, maxDepth: maxDepth, currentDepth: currentDepth + 1, width: width - defaultListInset.leading * 2)
			}
		}
			.padding(.leading, insets.leading)
	}
}

private struct SubredditPostCommentContent: View {
	let comment: RedditComment
	let currentDepth: Int
	@Binding var collapsed: Bool
	let width: CGFloat

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Group {
			if !collapsed && !comment.deleted {
				SubredditPostCommentFromUser(comment: comment, width: width)
			} else {
				VStack(alignment: .leading) {
					if collapsed {
						Text("\(comment.deleted ? "deleted, " : "")collapsed " + (comment.replies?.values.count ?? 0).pluralize("direct reply", drops: 1, suffix: "ies"))
					} else if comment.childIDs != nil {
						Text("+\(comment.childIDs!.count) more")
					} else {
						RelativeText("deleted", since: comment.creationDate!, "ago")
					}
				}
					.frame(minHeight: 24)
					.foregroundColor(.secondary)
					.font(.footnote)
			}
		}
			.background(Group {
				if currentDepth > 0 {
					Color.accentColor
						.hueRotation(.degrees(Double(currentDepth - 1) * 31))
						.frame(width: 1)
						.offset(x: -insets.leading - 1)
				}
			}, alignment: .topLeading)
			.frame(maxWidth: .infinity, alignment: .leading)
			.contentShape(Rectangle())
			.modifier(
				ListRowSwipeModifier(
					inList: false, insets: insets,
					leading: collapsed ? nil : [
						SwipeSegment(primary: .upvote, reset: .upvoteRemove, shouldReset: { comment.userVote > 0 }) { action in
							comment.toggleVote(action == .upvote ? 1 : 0, in: context)
						},
						SwipeSegment(primary: .downvote, reset: .downvoteRemove, shouldReset: { comment.userVote < 0 }) { action in
							comment.toggleVote(action == .downvote ? -1 : 0, in: context)
						},
					],
					trailing: collapsed
						? [
							SwipeSegment(primary: .collapse, reset: .collapseReset, shouldReset: { collapsed }) { action in
								withAnimation {
									collapsed = action == .collapse
								}
							},
						]
						: [
							SwipeSegment(primary: .collapse, reset: .collapseReset, shouldReset: { collapsed }) { action in
								withAnimation {
									collapsed = action == .collapse
								}
							},
							SwipeSegment(primary: .save, reset: .unsave, shouldReset: { comment.userSaved }) { action in
								comment.performSaved(action == .save, in: context)
							},
						]
				)
			)
	}
}

private struct SubredditPostCommentFromUser: View {
	let comment: RedditComment
	let width: CGFloat

	var body: some View {
		VStack(alignment: .leading, spacing: 3) {
			BodyText(entity: comment, width: width)
			HStack {
				ScoreMetadata(entity: comment)
				AwardsMetadata(entity: comment)
				TextLabel(prefix: "u/", title: comment.author!)
				RelativeIcon(since: comment.creationDate)
				SavedMetadata(entity: comment)
			}
				.font(Font.caption.monospacedDigit())
		}
	}
}

#if DEBUG
struct SubredditPostComments_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext
	private static let comments = RedditListing<RedditComment>(asset: .comments)

	static var previews: some View {
		GeometryReader { geometry in
			List {
				SubredditPostCommentGroup(comments: comments, maxDepth: 2, currentDepth: 0, width: geometry.size.width)
			}
		}
			.environment(\.managedObjectContext, context)
	}
}
#endif
