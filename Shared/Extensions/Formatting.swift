import Foundation

extension TimeInterval {
	static let second: Self = 1
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

extension Int {
	var estimatedDescription: String {
		guard self >= 1000 else {
			return description
		}
		var thousands = Double(self) / 1000
		let suffix: String
		if thousands >= 1000 {
			thousands /= 1000
			suffix = "M"
		} else {
			suffix = "K"
		}
		let estimate: String
		if thousands > 100 {
			estimate = Int(thousands.rounded(.down)).description
		} else {
			let formattedThousands = String(format: "%.1f", thousands)
			estimate = formattedThousands.last == "0" ? String(formattedThousands.dropLast(2)) : formattedThousands
		}
		return estimate + suffix
	}
}
