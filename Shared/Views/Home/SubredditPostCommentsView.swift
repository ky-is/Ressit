import SwiftUI

struct SubredditPostCommentsView: View {
	let commentsViewModel: SubredditPostCommentsViewModel

	var body: some View {
		RedditView(commentsViewModel) { result in
			SubredditPostCommentGroup(comments: result.comments, maxBreadth: 99, maxDepth: 10, currentDepth: 0)
				.padding(.horizontal)
		}
	}
}

private struct SubredditPostCommentGroup: View {
	let comments: RedditListing<SubredditPostComment>
	let maxBreadth: Int
	let maxDepth: Int
	let currentDepth: Int

	private static let horizontalPadding: CGFloat = 12
	private static let veritcalPadding: CGFloat = 12

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			ForEach(comments.values.prefix(maxBreadth)) { comment in
				VStack(alignment: .leading, spacing: 0) {
					Divider()
						.background(Color.secondary)
					SubredditPostCommentContent(comment: comment)
						.padding(.vertical, SubredditPostCommentGroup.veritcalPadding)
						.background(
							Group { if self.currentDepth > 0 {
								Color.accentColor
									.hueRotation(.degrees(Double(self.currentDepth - 1) * 31))
									.frame(width: 1)
									.padding(.bottom, SubredditPostCommentGroup.veritcalPadding)
									.offset(x: -SubredditPostCommentGroup.horizontalPadding)
							}}
						, alignment: .topLeading)
					if comment.replies != nil && self.currentDepth < self.maxDepth {
						SubredditPostCommentGroup(comments: comment.replies!, maxBreadth: self.maxBreadth, maxDepth: self.maxDepth, currentDepth: self.currentDepth + 1)
					}
				}
					.padding(.leading, SubredditPostCommentGroup.horizontalPadding)
			}
		}
	}
}

private struct SubredditPostCommentContent: View {
	let comment: SubredditPostComment

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			if comment.author != nil && comment.author != "[deleted]" {
				Text(comment.body!.trimmingCharacters(in: .whitespacesAndNewlines))
					.foregroundColor(comment.body != nil ? nil : .secondary)
					.font(.callout)
					.fixedSize(horizontal: false, vertical: true)
				HStack {
					Text("⬆︎")
						.foregroundColor(.secondary)
					+
					Text(comment.score!.description)
					Text("u/")
						.foregroundColor(.secondary)
					+
					Text(comment.author!)
					if comment.creationDate != nil {
						Text(comment.creationDate!.relativeToNow)
					}
				}
					.font(.caption)
			} else {
				Group {
					if comment.childIDs != nil {
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

struct SubredditPostCommentsView_Previews: PreviewProvider {
	static let comments = RedditListing<SubredditPostComment>(asset: .comments)

	static var previews: some View {
		ScrollView {
			SubredditPostCommentGroup(comments: comments, maxBreadth: 2, maxDepth: 2, currentDepth: 0)
				.padding(.horizontal)
		}
	}
}
