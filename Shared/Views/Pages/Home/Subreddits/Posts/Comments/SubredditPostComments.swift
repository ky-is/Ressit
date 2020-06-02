import SwiftUI

struct SubredditPostComments: View {
	let post: UserPost

	let commentsViewModel: SubredditPostCommentsViewModel

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		RedditView(commentsViewModel, loadingHeight: 128) { result in
			if result.comments.values.isEmpty {
				Text("No comments yet...")
					.font(.subheadline)
					.foregroundColor(.secondary)
					.padding()
			} else {
				SubredditPostCommentGroup(comments: result.comments, maxDepth: 20, currentDepth: 0)
					.onAppear {
						self.post.update(fromRemote: result.post, in: self.context)
					}
			}
		}
	}
}

private struct SubredditPostCommentGroup: View {
	let comments: RedditListing<RedditComment>
	let maxDepth: Int
	let currentDepth: Int

	var body: some View {
		ForEach(comments.values) { comment in
			SubredditPostCommentTree(comment: comment, maxDepth: self.maxDepth, currentDepth: self.currentDepth)
		}
			.listRowInsets(.zero)
	}
}

private let insets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)

private struct SubredditPostCommentTree: View {
	let comment: RedditComment
	let maxDepth: Int
	let currentDepth: Int
	private let isRoot: Bool

	@State private var collapsed = false

	init(comment: RedditComment, maxDepth: Int, currentDepth: Int) {
		self.comment = comment
		self.maxDepth = maxDepth
		self.currentDepth = currentDepth
		self._collapsed = State(initialValue: comment.deleted)
		self.isRoot = currentDepth == 0
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			Divider()
				.background(isRoot ? Color.secondary : nil)
				.padding(.leading, isRoot ? 16 - insets.leading : 0)
			SubredditPostCommentContent(comment: comment, currentDepth: currentDepth, collapsed: $collapsed)
				.onTapGesture {
					if self.comment.childIDs == nil {
						withAnimation {
							self.collapsed.toggle()
						}
					}
				}
			if !collapsed && comment.replies != nil && currentDepth < maxDepth {
				SubredditPostCommentGroup(comments: comment.replies!, maxDepth: maxDepth, currentDepth: currentDepth + 1)
			}
		}
			.padding(.leading, insets.leading)
	}
}

private struct SubredditPostCommentContent: View {
	let comment: RedditComment
	let currentDepth: Int
	@Binding var collapsed: Bool

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Group {
			if !collapsed && !comment.deleted {
				SubredditPostCommentFromUser(comment: comment)
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
						.hueRotation(.degrees(Double(self.currentDepth - 1) * 31))
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
						SwipeSegment(primary: .upvote, reset: .upvoteRemove, shouldReset: { self.comment.userVote > 0 }) { action in
							self.comment.toggleVote(action == .upvote ? 1 : 0, in: self.context)
						},
						SwipeSegment(primary: .downvote, reset: .downvoteRemove, shouldReset: { self.comment.userVote < 0 }) { action in
							self.comment.toggleVote(action == .downvote ? -1 : 0, in: self.context)
						},
					],
					trailing: collapsed
						? [
							SwipeSegment(primary: .collapse, reset: .collapseReset, shouldReset: { self.collapsed }) { action in
								withAnimation {
									self.collapsed = action == .collapse
								}
							},
						]
						: [
							SwipeSegment(primary: .collapse, reset: .collapseReset, shouldReset: { self.collapsed }) { action in
								withAnimation {
									self.collapsed = action == .collapse
								}
							},
							SwipeSegment(primary: .save, reset: .unsave, shouldReset: { self.comment.userSaved }) { action in
								self.comment.performSaved(action == .save, in: self.context)
							},
						]
				)
			)
	}
}

private struct SubredditPostCommentFromUser: View {
	let comment: RedditComment

	var body: some View {
		VStack(alignment: .leading, spacing: 3) {
			Text(comment.body!.trimmingCharacters(in: .whitespacesAndNewlines))
				.foregroundColor(comment.body != nil ? nil : .secondary)
				.font(.callout)
				.fixedSize(horizontal: false, vertical: true)
			HStack {
				ScoreMetadata(entity: comment)
				AwardsMetadata(entity: comment)
				Text("u/")
					.foregroundColor(.secondary)
				+
				Text(comment.author!)
				RelativeIcon(since: comment.creationDate)
				SavedMetadata(entity: comment)
			}
				.font(Font.caption.monospacedDigit())
		}
	}
}

#if DEBUG
struct SubredditPostComments_Previews: PreviewProvider {
	private static let context = CoreDataModel().persistentContainer.viewContext
	private static let comments = RedditListing<RedditComment>(asset: .comments)

	static var previews: some View {
		List {
			SubredditPostCommentGroup(comments: comments, maxDepth: 2, currentDepth: 0)
		}
			.environment(\.managedObjectContext, context)
	}
}
#endif
