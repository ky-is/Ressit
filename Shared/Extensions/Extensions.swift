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
	subscript(clamped index: Index) -> Element {
		guard index >= startIndex else {
			return first!
		}
		guard index <= endIndex else {
			return last!
		}
		return self[index]
	}
}

extension URL {
	var hostDescription: String? {
		guard let host = host else {
			return nil
		}
		return host.starts(with: "www.") ? String(host.dropFirst(4)) : host
	}
}

extension TimeInterval {
	static let minute: Self = 60
	static let hour: Self = minute * 60
	static let day: Self = hour * 24
	static let week: Self = day * 7
	static let month: Self = year / 12
	static let year: Self = day * 365.25
}

extension RelativeDateTimeFormatter {
	static let `default`: RelativeDateTimeFormatter = {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .abbreviated
		formatter.dateTimeStyle = .numeric
		return formatter
	}()
}

extension Date {
	private static let checkComponents: [(interval: TimeInterval, label: String)] = [(.year, "y"), (.month, "m"), (.week, "w"), (.day, "d"), (.hour, "h"), (.minute, "m"), (1, "s")]

	func relativeComponents(maxCount: Int = 1) -> String {
		var interval = abs(timeIntervalSinceNow)
		var components: [String] = []
		for check in Self.checkComponents {
			if interval > check.interval {
				let n = (interval / check.interval).rounded(.down)
				components.append("\(Int(n))\(check.label)")
				if components.count >= maxCount {
					break
				}
				interval = interval.truncatingRemainder(dividingBy: .year)
			}
		}
		return components.joined(separator: " ")
	}

	var relativeToNow: String {
		RelativeDateTimeFormatter.default.localizedString(for: self, relativeTo: Date())
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
