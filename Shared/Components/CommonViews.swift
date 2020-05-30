import SwiftUI
import SafariServices

struct SubredditTitle: View {
	let name: String?

	var body: some View {
		Group {
			if name != nil {
				HStack(spacing: 1) {
					Text("r/")
						.foregroundColor(.secondary)
					Text(name!)
				}
					.lineLimit(1)
			} else {
				Text("🌏 Global Feed")
			}
		}
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

struct SafariView: UIViewControllerRepresentable {
	let url: URL

	func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
		return SFSafariViewController(url: url)
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
	}
}

struct LoadingView: View {
	var body: some View {
		Image(systemName: "ellipsis")
			.font(.largeTitle)
	}
}
