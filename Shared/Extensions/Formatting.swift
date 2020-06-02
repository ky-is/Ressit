import Foundation

extension TimeInterval {
	static let minute: Self = 60
	static let hour: Self = minute * 60
	static let day: Self = hour * 24
	static let week: Self = day * 7
	static let month: Self = year / 12
	static let year: Self = day * 365.25

	private static let componentLabels: [(interval: TimeInterval, label: String)] = [(.year, "y"), (.month, "mo"), (.week, "w"), (.day, "d"), (.hour, "h"), (.minute, "m"), (1, "s")]

	func relativeComponents(maxCount: Int = 1) -> String {
		var interval = abs(self)
		var components: [String] = []
		for check in Self.componentLabels {
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
}

extension Date {
	func relativeComponents(maxCount: Int = 1) -> String {
		return timeIntervalSinceNow.relativeComponents(maxCount: maxCount)
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
