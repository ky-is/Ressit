import SwiftUI

let defaultListInset = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
private let swipeActivationMagnitude: CGFloat = 64

private var activatedSwipeSegment: SwipeSegment?
#if os(iOS)
private var feedbackGenerator: UIImpactFeedbackGenerator?
#endif

struct SwipeSegment: Equatable {
	static func == (lhs: SwipeSegment, rhs: SwipeSegment) -> Bool {
		lhs.primary == rhs.primary
	}

	let primary: PostSwipeAction
	let reset: PostSwipeAction?
	let shouldReset: () -> Bool
	let activate: (PostSwipeAction) -> Void

	var enabledAction: PostSwipeAction {
		guard let reset = reset else {
			return primary
		}
		return shouldReset() ? reset : primary
	}
}

struct PostListRowSwipeModifier: ViewModifier {
	let post: UserPost

	@Environment(\.managedObjectContext) private var context

	func body(content: Content) -> some View {
		content.modifier(
			ListRowSwipeModifier(
				leading: [
					SwipeSegment(primary: .upvote, reset: .upvoteRemove, shouldReset: { post.userVote > 0 }) { action in
						post.toggleVote(action == .upvote ? 1 : 0, in: context)
					},
					SwipeSegment(primary: .downvote, reset: .downvoteRemove, shouldReset: { post.userVote < 0 }) { action in
						post.toggleVote(action == .downvote ? -1 : 0, in: context)
					},
				],
				trailing: [
					SwipeSegment(primary: .markRead, reset: .markUnread, shouldReset: { post.metadata?.readDate != nil }) { action in
						post.performRead(action == .markRead, in: context)
					},
					SwipeSegment(primary: .save, reset: .unsave, shouldReset: { post.userSaved }) { action in
						post.performSaved(action == .save, in: context)
					},
				]
			)
		)
	}
}

struct ListRowSwipeModifier: ViewModifier {
	let inList: Bool
	let insets: EdgeInsets
	let leading: [SwipeSegment]?
	let trailing: [SwipeSegment]?

	init(inList: Bool = true, insets: EdgeInsets = defaultListInset, leading: [SwipeSegment]? = nil, trailing: [SwipeSegment]? = nil) {
		self.inList = inList
		self.leading = leading
		self.trailing = trailing
		self.insets = insets
	}

	@State private var swipeAction: PostSwipeAction?
	@State private var swipeEdge: Edge?
	@GestureState private var swipeDistance: CGFloat = .zero
	
	private func getSwipeDistance(from value: DragGesture.Value) -> CGFloat {
		return value.translation.width
	}

	func body(content: Content) -> some View {
		ZStack {
			if swipeAction != nil && swipeEdge != nil {
				PostSwipeActionView(action: swipeAction!, edge: swipeEdge!, offset: swipeDistance)
					.padding(.vertical, inList ? -insets.top : -0.5)
					.offset(x: swipeEdge == .leading ? -insets.leading : insets.trailing)
			}
			content
				.frame(maxWidth: .infinity, alignment: .leading)
				.offset(x: swipeDistance)
				.padding(inList ? .zero : insets)
				.gesture(
					DragGesture(minimumDistance: 20)
						.updating($swipeDistance) { value, swipeDistance, transaction in
							guard value.startLocation.x > 10.5 else { // Prevent overlap with system left edge back gesture
								return
							}
							let distance: CGFloat
							let didActivateSegment: Bool
							let displaySegment: SwipeSegment?
							let swipeEdge: Edge?
							if value.translation.height.magnitude > 128 { // Disable action when swiping too far vertically
								distance = 0
								didActivateSegment = false
								displaySegment = nil
								swipeEdge = nil
							} else {
								distance = getSwipeDistance(from: value).resist(over: 256)
								let isLeadingSwipe = distance > 0
								swipeEdge = isLeadingSwipe ? .leading : (distance < 0 ? .trailing : nil)
								if let directionSegments = isLeadingSwipe ? leading : trailing {
									let activationsSwipedCount = distance.magnitude / swipeActivationMagnitude
									let segmentIndex = Int(floor(activationsSwipedCount)) - 1
									didActivateSegment = segmentIndex >= 0
									displaySegment = directionSegments[clamped: segmentIndex]
									#if os(iOS)
									if feedbackGenerator == nil {
										feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
										feedbackGenerator?.prepare()
									}
									#endif
								} else {
									didActivateSegment = false
									displaySegment = nil
								}
							}
							swipeDistance = distance
							let displayAction = displaySegment?.enabledAction
							if swipeAction != displayAction {
								DispatchQueue.main.async {
									swipeAction = displayAction
									self.swipeEdge = swipeEdge
								}
							}
							let activatedSection = didActivateSegment ? displaySegment : nil
							if activatedSwipeSegment != activatedSection {
								activatedSwipeSegment = activatedSection
								#if os(iOS)
								feedbackGenerator?.impactOccurred(intensity: didActivateSegment ? 1 : 0.5)
								feedbackGenerator?.prepare()
								#endif
							}
						}
						.onEnded { _ in
							if let segment = activatedSwipeSegment {
								segment.activate(segment.enabledAction)
								activatedSwipeSegment = nil
							}
						}
				)
		}
			.listRowInsets(inList ? insets : .zero)
			.animation(swipeDistance == 0 ? .default : nil, value: swipeDistance)
	}
}

private struct PostSwipeActionView: View {
	let action: PostSwipeAction
	let edge: Edge
	let offset: CGFloat

	var body: some View {
		let alignment: Alignment = edge == .leading ? .leading : .trailing
		let unitVector = edge.unitVector
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
			.frame(maxWidth: .infinity, alignment: alignment)
	}
}

enum PostSwipeAction {
	case downvote, downvoteRemove
	case upvote, upvoteRemove
	case markRead, markUnread
	case save, unsave
	case collapse, collapseReset

	var color: Color {
		switch self {
		case .upvote, .upvoteRemove:
			return .orange
		case .downvote, .downvoteRemove:
			return .blue
		case .markRead, .markUnread, .collapse, .collapseReset:
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
		case .collapse:
			return "arrow.down.right.and.arrow.up.left"
		case .collapseReset:
			return "arrow.up.left.and.arrow.down.right"
		}
	}
}
