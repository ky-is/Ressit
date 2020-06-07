import SwiftUI

struct SubredditTitle: View {
	let name: String?

	var body: some View {
		HStack(spacing: 1) {
			if name != nil {
				Text("r/")
					.foregroundColor(.secondary)
				Text(name!)
			} else {
				Image(systemName: "globe")
					.foregroundColor(.accentColor)
				Text(" Global Feed")
			}
		}
			.lineLimit(1)
	}
}

struct HiddenNavigationLink<Destination: View>: View {
	@Binding var isActive: Bool
	let destination: Destination

	var body: some View {
		NavigationLink(destination: destination, isActive: $isActive) {
			EmptyView()
		}
			.hidden()
	}
}

struct IconText: View {
	let iconName: String
	let label: String

	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: iconName)
				.foregroundColor(.secondary)
			Text(label)
				.fixedSize()
		}
	}
}

struct ScoreMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		HStack(spacing: 2) {
			Image(systemName: "arrow.up")
				.foregroundColor(entity.voteColor())
				.animation(.default)
				.rotationEffect(entity.userVote < 0 ? .degrees(180) : .zero)
			Text(entity.score.estimatedDescription)
				.fixedSize()
		}
	}
}

struct CommentsMetadata: View {
	@ObservedObject var post: UserPost

	var body: some View {
		IconText(iconName: "bubble.left.and.bubble.right", label: post.commentCount.description)
	}
}

struct AwardsMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		Group {
			if entity.awardCount > 0 {
				IconText(iconName: "gift", label: entity.awardCount.description)
			}
		}
	}
}

struct SavedMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		Group {
			if entity.userSaved {
				Image(systemName: "bookmark.fill")
					.foregroundColor(.green)
			}
		}
	}
}

struct BodyText<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity
	let width: CGFloat

	var body: some View {
		Group {
			if entity.attributedString != nil {
				TextAttributed(attributedString: entity.attributedString!, width: width)
					.padding(.bottom, -16)
			} else {
				Text("")
			}
		}
	}
}
