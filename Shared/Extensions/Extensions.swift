import SwiftUI

extension Sequence {
	func reduce<Result>(_ initialValue: Result, _ operation: (Result, Result) -> Result, _ keyPath: KeyPath<Element, Result>) -> Result {
		return reduce(initialValue) { operation($0, $1[keyPath: keyPath]) }
	}

	func contains<Value>(_ keyPath: KeyPath<Element, Value>, _ operation: (Value, Value) -> Bool, _ comparedTo: Value) -> Bool {
		return contains { operation($0[keyPath: keyPath], comparedTo) }
	}

	func filter<Value>(_ keyPath: KeyPath<Element, Value>, _ operation: (Value, Value) -> Bool, _ comparedTo: Value) -> [Element] {
		return filter { operation($0[keyPath: keyPath], comparedTo) }
	}

	func sorted<Value>(_ keyPath: KeyPath<Element, Value>, _ operation: (Value, Value) -> Bool) -> [Element] {
		return sorted { operation($0[keyPath: keyPath], $1[keyPath: keyPath]) }
	}
}

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
		guard index < endIndex else {
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

extension BinaryInteger {
	func pluralize(_ word: String, drops: Int = 0, suffix: String = "s") -> String {
		let resultWord = self == 1 ? word : word.dropLast(drops) + suffix
		return "\(self) \(resultWord)"
	}
}
