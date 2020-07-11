import SwiftUI

struct FaintIconLabelStyle: LabelStyle {
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.icon
				.foregroundColor(.secondary)
			configuration.title
		}
	}
}

struct TextIconLabelStyle: LabelStyle {
	func makeBody(configuration: Configuration) -> some View {
		HStack(spacing: 0) {
			configuration.icon
				.foregroundColor(.secondary)
			configuration.title
		}
	}
}

struct TextLabel: View {
	let prefix: String
	let title: String

	var body: some View {
		Label {
			Text(title)
		} icon: {
			Text(prefix)
		}
			.labelStyle(TextIconLabelStyle())
	}
}
