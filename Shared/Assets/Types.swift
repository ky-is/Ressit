import SwiftUI

#if os(macOS)
import AppKit

typealias UXColor = NSColor
extension UXColor {
	static let systemBackground = windowBackgroundColor
}

typealias UXFont = NSFont

typealias UXImage = NSImage
typealias UXImageView = NSImageView

typealias NSDataAssetName = NSDataAsset.Name

typealias StackNavigationViewStyle = DefaultNavigationViewStyle

typealias UXView = NSView
typealias UXTextView = NSTextView

typealias UXViewRepresentable = NSViewRepresentable
typealias UXViewControllerRepresentable = NSViewControllerRepresentable

#else
import UIKit

typealias UXColor = UIColor

typealias UXFont = UIFont

typealias UXImage = UIImage
typealias UXImageView = UIImageView

typealias UXView = UIView
typealias UXTextView = UITextView

typealias UXViewRepresentable = UIViewRepresentable
typealias UXViewControllerRepresentable = UIViewControllerRepresentable
#endif

extension Image {
	init(uxImage: UXImage) {
		#if os(macOS)
		self.init(nsImage: uxImage)
		#else
		self.init(uiImage: uxImage)
		#endif
	}
}
