import SwiftUI
import Combine

fileprivate final class RelativeTimer: ObservableObject {
	static let shared = RelativeTimer()

	@Published var minute = Date().timeIntervalSinceReferenceDate

	private var subscription: AnyCancellable?

	private init() {
		subscription = Timer.publish(every: .minute, tolerance: .minute, on: RunLoop.main, in: .default)
			.autoconnect()
			.map(\.timeIntervalSinceReferenceDate)
			.assign(to: \.minute, on: self)
	}
}

private func timeComponents(at now: TimeInterval = Date().timeIntervalSinceReferenceDate, since reference: TimeInterval) -> String {
	return (now - reference).relativeComponents()
}

struct RelativeText: View {
	let reference: TimeInterval
	let prefix: String?
	let suffix: String?
	let font: Font

	@State private var components: String

	init(_ prefix: String? = nil, since date: Date, _ suffix: String? = nil, font: Font = .caption) {
		let reference = date.timeIntervalSinceReferenceDate
		self.reference = reference
		self.prefix = prefix
		self.suffix = suffix
		self.font = font.monospacedDigit()
		self._components = State(initialValue: timeComponents(since: reference))
	}

	var body: some View {
		Text(text)
			.font(font)
			.onReceive(RelativeTimer.shared.$minute) { interval in
				let new = timeComponents(at: interval, since: self.reference)
				if new != self.components {
					self.components = new
				}
			}
	}

	private var text: String {
		var text = components
		if prefix != nil {
			text = "\(prefix!) \(text)"
		}
		if suffix != nil {
			text = "\(text) \(suffix!)"
		}
		return text
	}
}

struct RelativeIcon: View {
	let reference: TimeInterval?
	let font: Font

	@State private var components: String

	init(since date: Date?, font: Font = .caption) {
		let reference = date?.timeIntervalSinceReferenceDate
		self.reference = reference
		self.font = font.monospacedDigit()
		self._components = State(initialValue: reference != nil ? timeComponents(since: reference!) : "?")
	}

	var body: some View {
		IconText(iconName: "clock", label: components)
			.font(font)
			.onReceive(RelativeTimer.shared.$minute) { interval in
				if let reference = self.reference {
					let new = timeComponents(at: interval, since: reference)
					if new != self.components {
						self.components = new
					}
				}
			}
	}
}

struct RelativeTime_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			RelativeText("tested", since: Date().addingTimeInterval(-.month), "ago")
			RelativeIcon(since: Date().addingTimeInterval(-.day))
		}
	}
}
