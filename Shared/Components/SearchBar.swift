import SwiftUI

struct SearchBar: UIViewRepresentable {
	@Binding var text: String
	let autoFocus: Bool

	func makeCoordinator() -> SearchBar.Coordinator {
		return Coordinator(text: $text)
	}

	func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
		let searchBar = UISearchBar(frame: .zero)
		searchBar.delegate = context.coordinator
		searchBar.autocapitalizationType = .none
		if autoFocus {
			searchBar.becomeFirstResponder()
		}
		searchBar.text = text
		return searchBar
	}

	func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
		uiView.text = text
	}

	final class Coordinator: NSObject, UISearchBarDelegate {
		@Binding var text: String

		init(text: Binding<String>) {
			_text = text
		}

		func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
			text = searchText
		}
	}
}
