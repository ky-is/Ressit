import SwiftUI
import Combine

struct TextAttributed: UIViewRepresentable {
	let attributedString: NSAttributedString
	let width: CGFloat

	internal func makeCoordinator() -> Self.Coordinator {
		return Coordinator()
	}

	func makeUIView(context: Context) -> FixedTextView {
		let view = FixedTextView(attributedString: attributedString, width: width)
		view.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.tint]
		view.delegate = context.coordinator
		return view
	}

	func updateUIView(_ view: FixedTextView, context: Context) {}

	final class Coordinator: NSObject, UITextViewDelegate {
		func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
			if url.scheme == "applewebdata" {
				let prefix = url.relativePath.prefix(3)
				if prefix == "/u/" || prefix == "/r/" {
					if let url = URL(string: url.relativePath, relativeTo: URL(string: "https://reddit.com")) {
						UIApplication.shared.open(url)
					}
					return false
				}
				print("Unknown url", url)
			}
			return true
		}
	}
}

internal final class FixedTextView: UITextView {
	private var flexibleHeightSize: CGSize!

	init(attributedString: NSAttributedString, width: CGFloat) {
		super.init(frame: .zero, textContainer: nil)
		attributedText = attributedString
		insetsLayoutMarginsFromSafeArea = false
		isEditable = false
		isScrollEnabled = false
		textColor = .label
		let padding = textContainer.lineFragmentPadding
		textContainerInset = UIEdgeInsets(top: 0, left: -padding, bottom: 0, right: -padding)
		flexibleHeightSize = sizeThatFits(CGSize(width: width, height: .infinity))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var intrinsicContentSize: CGSize {
		flexibleHeightSize
	}
}
