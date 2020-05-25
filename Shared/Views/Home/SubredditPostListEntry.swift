import SwiftUI

private let listInset = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
private let swipeActivationMagnitude: CGFloat = 64

private var activeSwipeAction: PostSwipeAction?
private var feedbackGenerator: UISelectionFeedbackGenerator?

struct SubredditPostListEntry: View {
	let post: SubredditPostModel

	@State private var swipeAction: PostSwipeAction = .upvote
	@GestureState private var swipeDistance: CGFloat = .zero

	var body: some View {
		ZStack {
			SubredditPostButton(post: post)
				.offset(x: swipeDistance)
				.gesture(
					DragGesture(minimumDistance: 32)
						.updating($swipeDistance) { value, swipeDistance, transaction in
							let distance = self.getSwipeDistance(from: value).resist(over: 256)
							swipeDistance = distance
							if feedbackGenerator == nil {
								feedbackGenerator = UISelectionFeedbackGenerator()
								feedbackGenerator?.prepare()
							}
							DispatchQueue.main.async {
								if distance > 0 {
									self.swipeAction = .upvote
								} else if distance < 0 {
									let reachedSecondAction = distance.magnitude > swipeActivationMagnitude * 2
									if reachedSecondAction {
										self.swipeAction = .save
									} else {
										self.swipeAction = .markUnread //TODO .markRead
									}
								}
							}
							if self.swipeAction != activeSwipeAction {
								let activatedAction = distance.magnitude > swipeActivationMagnitude
								if activatedAction {
									activeSwipeAction = self.swipeAction
										feedbackGenerator?.selectionChanged()
								}
							}
						}
						.onEnded { _ in
							activeSwipeAction?.activate(for: self.post)
							activeSwipeAction = nil
						}
				)
				.frame(maxWidth: .infinity, alignment: .leading)
			PostSwipeActionView(action: swipeAction, offset: swipeDistance)
		}
			.animation(swipeDistance == .zero ? .default : nil, value: swipeDistance)
			.listRowInsets(listInset)
	}

	private func getSwipeDistance(from value: DragGesture.Value) -> CGFloat {
		return value.translation.width
	}
}

private struct PostSwipeActionView: View {
	let action: PostSwipeAction
	let offset: CGFloat

	var body: some View {
		let alignment: Alignment = action.edge == .leading ? .leading : .trailing
		let unitVector = action.edge.unitVector
		let activationMagnitude: CGFloat = 80
		return ZStack(alignment: alignment) {
			action.color
				.frame(width: offset.magnitude)
			Text(action.icon)
				.font(.system(size: swipeActivationMagnitude))
				.foregroundColor(.background)
				.frame(width: activationMagnitude)
				.offset(x: max(0, activationMagnitude - offset.magnitude) * -unitVector, y: -4)
		}
			.padding(.vertical, -listInset.top)
			.offset(x: action.edge == .leading ? -listInset.leading : listInset.trailing)
			.frame(maxWidth: .infinity, alignment: alignment)
	}
}

private struct SubredditPostButton: View {
	let post: SubredditPostModel

	var body: some View {
		ZStack {
			Button(action: {
				PostUserModel.shared.selected = self.post
			}) {
				VStack(alignment: .leading, spacing: 4) {
					Text(post.title)
						.font(.headline)
					HStack {
						Text("🔺") + Text(post.score.description)
						Text("💬") + Text(post.commentCount.description)
						Text("🕓") + Text(post.creationDate.relativeToNow)
					}
						.font(.caption)
				}
					.padding(.vertical, 6)
			}
		}
	}
}

private enum PostSwipeAction {
	case upvote
	case markRead, markUnread
	case save

	var edge: Edge {
		switch self {
		case .upvote:
			return .leading
		case .markRead, .markUnread, .save:
			return .trailing
		}
	}
	var color: Color {
		switch self {
		case .upvote:
			return .orange
		case .markRead, .markUnread:
			return .blue
		case .save:
			return .green
		}
	}
	var icon: String {
		switch self {
		case .upvote:
			return "⬆︎"
		case .markRead:
			return "⎗"
		case .markUnread:
			return "⎘"
		case .save:
			return "⟳"
		}
	}

	func activate(for post: SubredditPostModel) {
		print(#function, self, post.id)
		switch self {
		case .upvote:
			break
		case .markRead:
			break
		case .markUnread:
			break
		case .save:
			break
		}
	}
}

struct SubredditPostListEntry_Previews: PreviewProvider {
	static var previews: some View {
		let post = SubredditPostModel(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.score = 42
		post.commentCount = 8001
		post.creationDate = Date(timeIntervalSinceReferenceDate: 0)
		return SubredditPostListEntry(post: post)
	}
}
