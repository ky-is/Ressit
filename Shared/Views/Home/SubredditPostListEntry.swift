import SwiftUI
import CoreData

private let listInset = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
private let swipeActivationMagnitude: CGFloat = 64

private var activeSwipeAction: PostSwipeAction?
private var feedbackGenerator: UIImpactFeedbackGenerator?

struct SubredditPostListEntry: View {
	let post: SubredditPostModel

	@State private var swipeAction: PostSwipeAction = .upvote
	@GestureState private var swipeDistance: CGFloat = .zero
	@Environment(\.managedObjectContext) private var context

	var body: some View {
		ZStack {
			PostSwipeActionView(action: swipeAction, offset: swipeDistance)
			SubredditPostButton(post: post)
				.opacity(post.metadata?.readDate != nil ? 0.5 : 1)
				.offset(x: swipeDistance)
				.gesture(
					DragGesture(minimumDistance: 15)
						.updating($swipeDistance) { value, swipeDistance, transaction in
							guard value.startLocation.x > 10.5 else { // Prevent overlap with system back gesture
								return
							}
							let distance = self.getSwipeDistance(from: value).resist(over: 256)
							swipeDistance = distance
							if feedbackGenerator == nil {
								feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
								feedbackGenerator?.prepare()
							}
							let reachedAction = distance.magnitude > swipeActivationMagnitude
							let reachedSecondAction = distance.magnitude > swipeActivationMagnitude * 2
							let displayAction: PostSwipeAction
							if distance > 0 {
								displayAction = self.post.userVote > 0 ? .upvoteRemove : .upvote
							} else {
								if reachedSecondAction {
									displayAction = .save
								} else {
									displayAction = self.post.metadata?.readDate != nil ? .markUnread : .markRead
								}
							}
							if displayAction != self.swipeAction {
								DispatchQueue.main.async {
									self.swipeAction = displayAction
								}
							}
							let activeAction = reachedAction ? displayAction : nil
							if activeSwipeAction != activeAction {
								activeSwipeAction = activeAction
								feedbackGenerator?.impactOccurred(intensity: reachedAction ? 1 : 0.5)
								feedbackGenerator?.prepare()
							}
						}
						.onEnded { _ in
							activeSwipeAction?.performActivate(for: self.post, in: self.context)
							activeSwipeAction = nil
						}
				)
				.frame(maxWidth: .infinity, alignment: .leading)
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
		let activationMagnitudeRemaining = max(0, swipeActivationMagnitude - offset.magnitude)
		let activated = activationMagnitudeRemaining <= 0
		return ZStack(alignment: alignment) {
			action.color
				.frame(width: offset.magnitude)
			Text(action.icon)
				.font(.system(size: swipeActivationMagnitude))
				.foregroundColor(.background)
				.scaleEffect(activated ? 1 : 0.75)
				.opacity(activated ? 1 : 0.5)
				.animation(offset.magnitude > 10 ? .default : nil, value: activated)
				.frame(width: swipeActivationMagnitude)
				.offset(x: activationMagnitudeRemaining * -unitVector, y: -4)
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
						HStack(spacing: 0) {
							Text("⬆︎")
								.font(.system(size: 26))
								.foregroundColor(post.userVote > 0 ? .orange : .secondary)
								.padding(.top, -6)
							Text(post.score.description)
						}
						Text("💬") + Text(post.commentCount.description)
						Text("🕓") + Text(post.creationDate.relativeToNow)
					}
						.font(Font.caption.monospacedDigit())
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
			return "⎗"
		case .markUnread:
			return "⎘"
		case .save:
			return "★"
		case .unsave:
			return "☆"
		}
	}

	func performActivate(for post: SubredditPostModel, in context: NSManagedObjectContext) {
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
