import Foundation

extension Collection {
	var nonEmpty: Self? {
		return isEmpty ? nil : self
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
	var relativeToNow: String {
		RelativeDateTimeFormatter.default.localizedString(for: self, relativeTo: Date())
	}
}
