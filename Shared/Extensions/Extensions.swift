import SwiftUI

extension Collection {
	var nonEmpty: Self? {
		return isEmpty ? nil : self
	}

	subscript(safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}

extension Array {
	subscript(clamped index: Index) -> Element? {
		guard index >= startIndex else {
			return first
		}
		guard index <= endIndex else {
			return last
		}
		return self[index]
	}
}

extension BinaryFloatingPoint {
	var unitVector: Self {
		return self < 0 ? -1 : +1
	}

	func resist(over maximumDistance: Self) -> Self {
		return maximumDistance * Self(log(1 + Double(magnitude / maximumDistance))) * unitVector
	}
}

extension Edge {
	var unitVector: CGFloat {
		switch self {
		case .top, .leading:
			return 1
		case .bottom, .trailing:
			return -1
		}
	}
}
extension EdgeInsets {
	static let zero = Self(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension Sequence {
	func reduce<Result>(_ initialValue: Result, _ operation: (Result, Result) -> Result, _ keyPath: KeyPath<Element, Result>) -> Result {
		return reduce(initialValue) { operation($0, $1[keyPath: keyPath]) }
	}
}

extension BinaryInteger {
	func pluralize(_ word: String, drops: Int = 0, suffix: String = "s") -> String {
		let resultWord = self == 1 ? word : word.dropLast(drops) + suffix
		return "\(self) \(resultWord)"
	}
}
