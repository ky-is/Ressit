import SwiftUI
import CoreData

private let listInset = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
private let swipeActivationMagnitude: CGFloat = 64

private var activatedSwipeSegment: SwipeSegment?
private var feedbackGenerator: UIImpactFeedbackGenerator?

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

struct ListRowSwipeModifier: ViewModifier {
	let leading: [SwipeSegment]?
	let trailing: [SwipeSegment]?

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
			}
			content
				.frame(maxWidth: .infinity, alignment: .leading)
				.offset(x: swipeDistance)
				.gesture(
					DragGesture(minimumDistance: 18)
						.updating($swipeDistance) { value, swipeDistance, transaction in
							guard value.startLocation.x > 10.5 else { // Prevent overlap with system left edge back gesture
								return
							}
							let distance: CGFloat
							let displaySegment: SwipeSegment?
							let swipeEdge: Edge?
							let didReachSegment: Bool
							if value.translation.height.magnitude > 128 { // Disable action when swiping too far vertically
								distance = 0
								displaySegment = nil
								didReachSegment = false
								swipeEdge = nil
							} else {
								distance = self.getSwipeDistance(from: value).resist(over: 256)
								if feedbackGenerator == nil {
									feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
									feedbackGenerator?.prepare()
								}
								let isLeadingSwipe = distance > 0
								swipeEdge = isLeadingSwipe ? .leading : (distance < 0 ? .trailing : nil)
								guard let directionSegments = isLeadingSwipe ? self.leading : self.trailing else {
									return //TODO verify
								}
								didReachSegment = distance.magnitude > swipeActivationMagnitude
								let segmentIndex = distance.magnitude > swipeActivationMagnitude * 2 ? 1 : 0
								displaySegment = directionSegments[safe: segmentIndex]
							}
							swipeDistance = distance
							let displayAction = displaySegment?.enabledAction
							if self.swipeAction != displayAction {
								DispatchQueue.main.async {
									self.swipeAction = displayAction
									self.swipeEdge = swipeEdge
								}
							}
							let activeSection = didReachSegment ? displaySegment : nil
							if activatedSwipeSegment != activeSection {
								activatedSwipeSegment = activeSection
								feedbackGenerator?.impactOccurred(intensity: didReachSegment ? 1 : 0.5)
								feedbackGenerator?.prepare()
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
			.animation(swipeDistance == 0 ? .default : nil)
			.listRowInsets(listInset)
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
			.padding(.vertical, -listInset.top)
			.offset(x: edge == .leading ? -listInset.leading : listInset.trailing)
			.frame(maxWidth: .infinity, alignment: alignment)
	}
}

enum PostSwipeAction {
	case downvote, downvoteRemove
	case upvote, upvoteRemove
	case markRead, markUnread
	case save, unsave

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
}
