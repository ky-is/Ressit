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
				.opacity(post.metadata?.readDate != nil ? 2/3 : 1)
				.offset(x: swipeDistance)
				.gesture(
					DragGesture(minimumDistance: 18)
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
								if reachedSecondAction {
									displayAction = self.post.userVote < 0 ? .downvoteRemove : .downvote
								} else {
									displayAction = self.post.userVote > 0 ? .upvoteRemove : .upvote
								}
							} else {
								if reachedSecondAction {
									displayAction = self.post.userSaved ? .unsave : .save
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
			Image(systemName: action.iconName)
				.font(.system(size: swipeActivationMagnitude / 2))
				.foregroundColor(.background)
				.scaleEffect(activated ? 1 : 0.8)
				.opacity(activated ? 1 : 0.5)
				.animation(offset.magnitude > 10 ? .default : nil, value: activated)
				.frame(width: swipeActivationMagnitude)
				.offset(x: activationMagnitudeRemaining * -unitVector)
		}
			.padding(.vertical, -listInset.top)
			.offset(x: action.edge == .leading ? -listInset.leading : listInset.trailing)
			.frame(maxWidth: .infinity, alignment: alignment)
	}
}

private struct SubredditPostButton: View {
	let post: UserPost

	var body: some View {
		Button(action: {
			PostUserModel.shared.selected = self.post
		}) {
			HStack(alignment: .top) {
				if post.thumbnail != nil {
					DownloadImageView(viewModel: post.getThumbnailManager()!)
						.frame(width: 80, height: 80)
						.clipped()
						.cornerRadius(2)
				}
				VStack(alignment: .leading, spacing: 4) {
					Text(post.title)
						.font(.headline)
					HStack {
						ScoreMetadata(entity: post)
						IconText(iconName: "bubble.left.and.bubble.right", label: post.commentCount.description)
						IconText(iconName: "clock", label: post.creationDate?.relativeToNow ?? "")
						if post.userSaved {
							Image(systemName: "bookmark.fill")
								.foregroundColor(.green)
						}
					}
						.font(Font.caption.monospacedDigit())
				}
					.padding(.vertical, 6)
			}
		}
	}
}

private enum PostSwipeAction {
	case downvote, downvoteRemove
	case upvote, upvoteRemove
	case markRead, markUnread
	case save, unsave

	var edge: Edge {
		switch self {
		case .upvote, .upvoteRemove, .downvote, .downvoteRemove:
			return .leading
		case .markRead, .markUnread, .save, .unsave:
			return .trailing
		}
	}
	var color: Color {
		switch self {
		case .upvote, .upvoteRemove:
			return .orange
		case .downvote, .downvoteRemove:
			return .blue
		case .markRead, .markUnread:
			return .blue
		case .save:
			return .green
		case .unsave:
			return .red
		}
	}
	var iconName: String {
		switch self {
		case .upvote:
			return "arrow.up"
		case .upvoteRemove:
			return "arrow.up.circle.fill"
		case .downvote:
			return "arrow.down"
		case .downvoteRemove:
			return "arrow.down.circle.fill"
		case .markRead:
			return "envelope.open"
		case .markUnread:
			return "envelope.fill"
		case .save:
			return "bookmark.fill"
		case .unsave:
			return "bookmark"
		}
	}

	func performActivate(for post: UserPost, in context: NSManagedObjectContext) {
		switch self {
		case .upvote:
			post.toggleVote(1, in: context)
		case .upvoteRemove, .downvoteRemove:
			post.toggleVote(0, in: context)
		case .downvote:
			post.toggleVote(-1, in: context)
		case .markRead:
			post.toggleRead(true, in: context)
		case .markUnread:
			post.toggleRead(false, in: context)
		case .save:
			post.performSaved(true, in: context)
		case .unsave:
			post.performSaved(false, in: context)
		}
	}
}

struct SubredditPostListEntry_Previews: PreviewProvider {
	static var previews: some View {
		let post = UserPost(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.score = 42
		post.commentCount = 8001
		post.creationDate = Date(timeIntervalSinceReferenceDate: 0)
		return SubredditPostListEntry(post: post)
	}
}
