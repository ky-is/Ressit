import SwiftUI

struct PriorityButton: View {
	@ObservedObject var subreddit: UserSubreddit
	let size: CGFloat
	let tooltip: Bool

	@State private var tapped = false

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Button(action: {
			self.context.perform {
				if self.subreddit.priority >= 3 {
					self.subreddit.priority = 0
				} else {
					self.subreddit.priority += 1
					self.subreddit.periodAllDate = nil
					self.subreddit.periodYearDate = nil
					self.subreddit.periodMonthDate = nil
					self.subreddit.periodWeekDate = nil
				}
				self.context.safeSave()
				if self.tooltip {
					withAnimation {
						self.tapped = true
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
						withAnimation {
							self.tapped = false
						}
					}
				}
			}
		}) {
			StrengthIcon(level: subreddit.priority, size: size)
		}
			.buttonStyle(BorderlessButtonStyle())
			.background(
				HStack {
					if tooltip && tapped {
						Text(subreddit.priority == 0 ? "Weekly" : "\(subreddit.fetchCount) daily")
							.transition(AnyTransition.move(edge: .trailing).combined(with: AnyTransition.opacity))
							.modifier(TooltipTextModifier(size: size))
					}
				}
			)
	}
}

private struct TooltipTextModifier: ViewModifier {
	let size: CGFloat

	func body(content: Content) -> some View {
		let priorityWidth = -(size + size / 6) * 3
		let tooltipWidth: CGFloat = 128
		return content
			.background(Color.background)
			.font(Font.subheadline.smallCaps())
			.foregroundColor(.accentColor)
			.frame(width: tooltipWidth, alignment: .trailing)
			.offset(x: (priorityWidth - tooltipWidth) / 2 - 2)
	}
}

private struct StrengthIcon: View {
	let level: Int
	let size: CGFloat

	var body: some View {
		let bar = Capsule()
		return HStack(alignment: .bottom, spacing: size / 6) {
			ForEach(0..<3) { index in
				VStack {
					if index < self.level {
						bar.fill()
					} else {
						bar.strokeBorder(lineWidth: 2)
					}
				}
					.frame(width: self.size, height: self.size + self.size / 2 * CGFloat(index))
			}
		}
	}
}

struct PriorityButton_Previews: PreviewProvider {
	private static let context = CoreDataModel().persistentContainer.viewContext
	private static let size: CGFloat = 16

	static var previews: some View {
		StrengthIcon(level: 1, size: size)
			.overlay(Group {
				Text("4 daily")
					.modifier(TooltipTextModifier(size: size))
			})
			.environment(\.managedObjectContext, context)
	}
}
