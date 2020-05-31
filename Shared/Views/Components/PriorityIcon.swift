import SwiftUI

struct PriorityButton: View {
	@ObservedObject var subreddit: UserSubreddit
	let size: CGFloat

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Button(action: {
			self.context.perform {
				if self.subreddit.priority >= 2  {
					self.subreddit.priority = 0
				} else {
					self.subreddit.priority += 1
					self.subreddit.periodAllDate = nil
					self.subreddit.periodYearDate = nil
					self.subreddit.periodMonthDate = nil
					self.subreddit.periodWeekDate = nil
				}
				self.context.safeSave()
			}
		}) {
			StrengthIcon(level: subreddit.priority, size: size)
		}
			.buttonStyle(BorderlessButtonStyle())
	}
}

private struct StrengthIcon: View {
	let level: Int
	let size: CGFloat

	var body: some View {
		let bar = Capsule()
		return HStack(alignment: .bottom, spacing: size / 8) {
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

	static var previews: some View {
		StrengthIcon(level: 1, size: 16)
			.environment(\.managedObjectContext, context)
	}
}
