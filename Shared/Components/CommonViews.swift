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
