import SwiftUI

struct SectionVibrant<Content: View>: View {
	let label: String
	let content: () -> Content

	init(label: String, @ViewBuilder content: @escaping () -> Content) {
		self.label = label
		self.content = content
	}

	var body: some View {
		Section(header: HeaderView(label: label)) {
			content()
				.padding(.horizontal)
		}
			.listRowInsets(.zero)
	}
}

private struct HeaderView: View {
	let label: String

	var body: some View {
		ZStack(alignment: .leading) {
			BlurView(style: .systemChromeMaterial)
			Text(label)
				.font(Font.headline.smallCaps())
				.padding(.horizontal)
				.padding(.vertical, 5)
		}
	}
}

struct SectionVibrant_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			List {
				SectionVibrant(label: "Test") {
					Text("Test")
				}
			}
				.navigationBarTitle("Test", displayMode: .inline)
		}
	}
}
