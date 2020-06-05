import SwiftUI
import Combine

struct TextAttributed: UIViewRepresentable {
	let attributedString: NSAttributedString

	func makeUIView(context: Context) -> UILabel {
		let view = UILabel()
		view.attributedText = attributedString
		view.textColor = .label
		view.numberOfLines = 0
		view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		return view
	}

	func updateUIView(_ view: UILabel, context: Context) {}
}

//struct TextAttributed: UIViewRepresentable { //
//	let attributedString: NSAttributedString
//
//	func makeUIView(context: Context) -> UITextView {
//		let view = UITextView()
//		view.contentInset = .zero
//		view.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.tint]
//		view.attributedText = attributedString
//		view.textColor = .label
//		view.isScrollEnabled = false
//		view.isEditable = false
//		view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//		return view
//	}
//
//	func updateUIView(_ view: UITextView, context: Context) {}
//}
