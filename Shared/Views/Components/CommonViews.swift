import SwiftUI

struct SubredditTitle: View {
	let name: String?

	var body: some View {
		HStack(spacing: 1) {
			if name != nil {
				TextLabel(prefix: "r/", title: name!)
			} else {
				Label("Global Feed", systemImage: "globe")
					.labelStyle(FaintIconLabelStyle())
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

struct ScoreMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		Label {
			Text(entity.score.estimatedDescription)
				.fixedSize()
		} icon: {
			Image(systemName: "arrow.up")
				.foregroundColor(entity.voteColor())
				.animation(.default)
				.rotationEffect(entity.userVote < 0 ? .degrees(180) : .zero)
		}
	}
}

struct CommentsMetadata: View {
	@ObservedObject var post: UserPost

	var body: some View {
		Label(post.commentCount.description, systemImage: "bubble.left.and.bubble.right")
			.labelStyle(FaintIconLabelStyle())
	}
}

struct AwardsMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		Group {
			if entity.awardCount > 0 {
				Label(entity.awardCount.description, systemImage: "gift")
					.labelStyle(FaintIconLabelStyle())
			}
		}
	}
}

struct SavedMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		Group {
			if entity.userSaved {
				Label("Saved", image: "bookmark.fill")
					.labelStyle(IconOnlyLabelStyle())
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
