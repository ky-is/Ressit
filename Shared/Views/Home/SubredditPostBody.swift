import SwiftUI

struct SubredditPostBody: View {
	let post: SubredditPostModel

	let commentsViewModel: SubredditPostCommentsViewModel

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		RedditView(commentsViewModel) { result in
			SubredditPostCommentGroup(comments: result.comments, maxBreadth: 99, maxDepth: 20, currentDepth: 0)
				.padding(.horizontal)
				.onAppear {
					self.context.perform {
						self.post.toggleRead(true, in: self.context)
						self.context.safeSave()
					}
				}
		}
	}
}

private struct SubredditPostCommentGroup: View {
	let comments: RedditListing<SubredditPostComment>
	let maxBreadth: Int
	let maxDepth: Int
	let currentDepth: Int

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			ForEach(comments.values.prefix(maxBreadth)) { comment in
				SubredditPostCommentTree(comment: comment, maxBreadth: self.maxBreadth, maxDepth: self.maxDepth, currentDepth: self.currentDepth)
			}
		}
	}
}

private struct SubredditPostCommentTree: View {
	let comment: SubredditPostComment
	let maxBreadth: Int
	let maxDepth: Int
	let currentDepth: Int

	@State private var collapsed = false

	private static let horizontalPadding: CGFloat = 12
	private static let veritcalPadding: CGFloat = 12

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			Divider()
				.background(currentDepth == 0 ? Color.secondary : nil)
			SubredditPostCommentContent(comment: comment, currentDepth: currentDepth, collapsed: collapsed)
				.padding(.vertical, Self.veritcalPadding)
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
				.onTapGesture {
					if self.comment.childIDs == nil {
						withAnimation {
							self.collapsed.toggle()
						}
					}
				}
				.background(Group {
					if currentDepth > 0 {
						Color.accentColor
							.hueRotation(.degrees(Double(self.currentDepth - 1) * 31))
							.frame(width: 1)
							.padding(.bottom, Self.veritcalPadding)
							.offset(x: -Self.horizontalPadding)
					}
				}, alignment: .topLeading)
			if !collapsed && comment.replies != nil && currentDepth < maxDepth {
				SubredditPostCommentGroup(comments: comment.replies!, maxBreadth: maxBreadth, maxDepth: maxDepth, currentDepth: currentDepth + 1)
			}
		}
			.padding(.leading, currentDepth > 0 ? Self.horizontalPadding : 0)
	}
}

private struct SubredditPostCommentContent: View {
	let comment: SubredditPostComment
	let currentDepth: Int
	let collapsed: Bool

	var body: some View {
		Group {
			if !collapsed && comment.author != nil && comment.author != "[deleted]" {
				SubredditPostCommentFromUser(comment: comment)
			} else {
				Group {
					if collapsed {
						Text("collapsed \(comment.replies?.values.count ?? 0) direct replies")
					} else if comment.childIDs != nil {
						Text("+\(comment.childIDs!.count) more")
					} else {
						Text("deleted \(comment.creationDate!.relativeToNow)")
					}
				}
					.foregroundColor(.secondary)
					.font(.caption)
			}
		}
	}
}

private struct SubredditPostCommentFromUser: View {
	let comment: SubredditPostComment

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(comment.body!.trimmingCharacters(in: .whitespacesAndNewlines))
				.foregroundColor(comment.body != nil ? nil : .secondary)
				.font(.callout)
				.fixedSize(horizontal: false, vertical: true)
			HStack {
				ScoreMetadata(entity: comment)
				Text("u/")
					.foregroundColor(.secondary)
				+
				Text(comment.author!)
				if comment.creationDate != nil {
					Text(comment.creationDate!.relativeToNow)
				}
			}
				.font(Font.caption.monospacedDigit())
		}
	}
}

struct SubredditPostBody_Previews: PreviewProvider {
	static let comments = RedditListing<SubredditPostComment>(asset: .comments)

	static var previews: some View {
		ScrollView {
			SubredditPostCommentGroup(comments: comments, maxBreadth: 2, maxDepth: 2, currentDepth: 0)
				.padding(.horizontal)
		}
			.environment(\.managedObjectContext, CoreDataModel.persistentContainer.viewContext)
	}
}
