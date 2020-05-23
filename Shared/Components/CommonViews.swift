import SwiftUI

struct SubredditTitle: View {
	let name: String

	var body: some View {
		HStack(spacing: 1) {
			Text("r/")
				.foregroundColor(.secondary)
			Text(name)
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
