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

struct ScoreMetadata<Entity: RedditVotable>: View {
	@ObservedObject var entity: Entity

	var body: some View {
		HStack(spacing: 0) {
			Text("⬆︎")
				.font(.system(size: 26))
				.foregroundColor(entity.voteColor())
				.padding(.top, -6)
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
