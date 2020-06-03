import SwiftUI
import Combine

final class RelativeTimer: ObservableObject {
	static let shared = RelativeTimer()

	@Published var minute = Date().timeIntervalSinceReferenceDate

	private var subscription: AnyCancellable?

	private init() {
		subscription = Timer.publish(every: .minute, tolerance: .minute, on: RunLoop.main, in: .default)
			.autoconnect()
			.map(\.timeIntervalSinceReferenceDate)
			.assign(to: \.minute, on: self)
	}

	func update() {
		let now = Date.timeIntervalSinceReferenceDate
		if now - minute > .minute {
			minute = now
		}
	}
}

private func timeComponents(at now: TimeInterval = Date().timeIntervalSinceReferenceDate, since reference: TimeInterval) -> String {
	return (now - reference).relativeComponents()
}

struct RelativeText: View {
	let reference: TimeInterval
	let prefix: String?
	let suffix: String?

	@State private var components: String

	@Environment(\.font) private var font

	init(_ prefix: String? = nil, since date: Date, _ suffix: String? = nil) {
		let reference = date.timeIntervalSinceReferenceDate
		self.reference = reference
		self.prefix = prefix
		self.suffix = suffix
		self._components = State(initialValue: timeComponents(since: reference))
	}

	var body: some View {
		Text(text)
			.font((font ?? .caption).monospacedDigit())
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

	@State private var components: String

	@Environment(\.font) private var font

	init(since date: Date?) {
		let reference = date?.timeIntervalSinceReferenceDate
		self.reference = reference
		self._components = State(initialValue: reference != nil ? timeComponents(since: reference!) : "?")
	}

	var body: some View {
		IconText(iconName: "clock", label: components)
			.font((font ?? .caption).monospacedDigit())
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
