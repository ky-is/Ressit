import SwiftUI

struct HiddenModifier: ViewModifier {
	let hidden: Bool

	func body(content: Content) -> some View {
		Group {
			if hidden {
				content
					.hidden()
			} else {
				content
			}
		}
	}
}

extension View {
	func hidden(_ hidden: Bool) -> some View {
		modifier(HiddenModifier(hidden: hidden))
	}
}
