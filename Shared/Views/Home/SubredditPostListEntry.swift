import SwiftUI
import CoreData

private let listInset = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
private let swipeActivationMagnitude: CGFloat = 64

private var activeSwipeAction: PostSwipeAction?
private var feedbackGenerator: UISelectionFeedbackGenerator?

struct SubredditPostListEntry: View {
	let post: SubredditPostModel

	@State private var swipeAction: PostSwipeAction = .upvote
	@GestureState private var swipeDistance: CGFloat = .zero
	@Environment(\.managedObjectContext) private var context

	var body: some View {
		ZStack {
			SubredditPostButton(post: post)
				.opacity(post.metadata?.readDate != nil ? 0.5 : 1)
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
									self.swipeAction = self.post.userVote > 0 ? .upvoteRemove : .upvote
								} else if distance < 0 {
									let reachedSecondAction = distance.magnitude > swipeActivationMagnitude * 2
									if reachedSecondAction {
										self.swipeAction = .save
									} else {
										self.swipeAction = self.post.metadata?.readDate != nil ? .markUnread : .markRead
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
							activeSwipeAction?.activate(for: self.post, in: self.context)
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
						Text("⬆︎")
							.foregroundColor(post.userVote > 0 ? .orange : .secondary)
						+
						Text(post.score.description)
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
	case upvote, upvoteRemove
	case markRead, markUnread
	case save, unsave

	var edge: Edge {
		switch self {
		case .upvote, .upvoteRemove:
			return .leading
		case .markRead, .markUnread, .save, .unsave:
			return .trailing
		}
	}
	var color: Color {
		switch self {
		case .upvote, .upvoteRemove:
			return .orange
		case .markRead, .markUnread:
			return .blue
		case .save:
			return .green
		case .unsave:
			return .red
		}
	}
	var icon: String {
		switch self {
		case .upvote:
			return "⬆︎"
		case .upvoteRemove:
			return "⇧"
		case .markRead:
			return "⎘"
		case .markUnread:
			return "⎗"
		case .save:
			return "★"
		case .unsave:
			return "☆"
		}
	}

	func activate(for post: SubredditPostModel, in context: NSManagedObjectContext) {
		context.perform {
			switch self { //TODO upload votes/saved
			case .upvote:
				post.toggleVote(1)
			case .upvoteRemove:
				post.toggleVote(0)
			case .markRead:
				post.toggleRead(true, in: context)
			case .markUnread:
				post.toggleRead(false, in: context)
			case .save:
				post.toggleSaved(true)
			case .unsave:
				post.toggleSaved(false)
			}
			context.safeSave()
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
