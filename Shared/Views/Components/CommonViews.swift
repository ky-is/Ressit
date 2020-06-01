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
	let isActive: Bool
	let destination: Destination

	var body: some View {
		NavigationLink(destination: destination, isActive: .constant(isActive)) {
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
			Text(entity.score.description)
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
