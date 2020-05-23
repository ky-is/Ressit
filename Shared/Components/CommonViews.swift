import SwiftUI

struct SubredditTitle: View {
	let name: String

	var body: some View {
		Text("r/")
			.foregroundColor(.secondary)
		+
		Text(name)
	}
}
