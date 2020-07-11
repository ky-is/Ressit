import SwiftUI
import Combine

struct TextAttributed: UXViewRepresentable {
	let attributedString: NSAttributedString
	let width: CGFloat

	internal func makeCoordinator() -> Self.Coordinator {
		return Coordinator()
	}

	#if os(macOS)
	func makeNSView(context: Context) -> FixedTextView { makeView(context: context) }
	func updateNSView(_ view: FixedTextView, context: Context) {}
	#else
	func makeUIView(context: Context) -> WKWebView { makeView(context: context) }
	func updateUIView(_ view: FixedTextView, context: Context) {}
	#endif

	func makeView(context: Context) -> FixedTextView {
		let view = FixedTextView(attributedString: attributedString, width: width)
		view.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UXColor.tint]
		#if os(iOS)
		view.delegate = context.coordinator
		#endif
		return view
	}

	#if os(iOS)
	final class Coordinator: NSObject, UITextViewDelegate {
		func textView(_ textView: UXTextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
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
	#endif
}

#if os(macOS)
internal final class FixedTextView: NSTextView {
	private var flexibleHeightSize: CGSize!

	init(attributedString: NSAttributedString, width: CGFloat) {
		super.init(frame: .zero, textContainer: nil)
		textStorage?.setAttributedString(attributedString)
		isEditable = false
		textColor = .labelColor
//		let padding = textContainer.lineFragmentPadding
		textContainerInset = .zero
//		flexibleHeightSize = sizeThatFits(CGSize(width: width, height: .infinity))
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var intrinsicContentSize: CGSize {
		flexibleHeightSize
	}
}
#else
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
#endif
