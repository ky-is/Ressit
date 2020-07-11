import Foundation

protocol RedditResponsable {
	init?(json: Any)
}

extension RedditResponsable {
	static func defaultJSONData(_ json: Any) -> [String: Any] {
		guard let baseJSON = json as? [String: Any] else {
			print(json)
			fatalError("JSON non-object")
		}
		guard let data = baseJSON["data"] as? [String: Any] else {
			print(baseJSON)
			fatalError("JSON invalid")
		}
		return data
	}
}

#if DEBUG
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension NSDataAssetName {
	static let comments = Self.init("comments")
	static let posts = Self.init("posts")
}

extension RedditResponsable {
	init(asset: NSDataAssetName) {
		self.init(json: try! JSONSerialization.jsonObject(with: NSDataAsset(name: asset)!.data))!
	}
}
#endif
