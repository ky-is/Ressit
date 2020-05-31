import Combine
import SwiftUI

struct SubredditsView: View {
	let subscriptions: [SubredditPostsViewModel]
	let inSplitView: Bool

	var body: some View {
		NavigationView {
			SubredditsContainer(subscriptions: subscriptions, inSplitView: inSplitView)
				.background(
					SelectedSubredditLink(inSplitView: inSplitView)
				)
		}
			.navigationViewStyle(StackNavigationViewStyle())
			.onAppear {
				SubredditUserModel.shared.selected = nil
				PostUserModel.shared.selected = nil
			}
	}
}

private struct SubredditsContainer: View {
	let subscriptions: [SubredditPostsViewModel]
	let inSplitView: Bool

	private let subredditSearch = SubredditsSearchViewModel()

	var body: some View {
		SubredditsSubscriptionList(subscriptions: subscriptions, subredditSearch: subredditSearch, inSplitView: inSplitView)
			.navigationBarTitle("Subreddits")
	}
}

private struct SubredditsSubscriptionList: View {
	let subscriptions: [SubredditPostsViewModel]
	let subredditSearch: SubredditsSearchViewModel
	let inSplitView: Bool

	@State private var showAddSubreddits = false
	@Environment(\.managedObjectContext) private var context

	var body: some View {
		let totalPostCount = subscriptions.count < 2 ? 0 : subscriptions.reduce(0, +, \.model!.postCount)
		var availableSubscriptions: [SubredditPostsViewModel] = []
		var unavailableSubscriptions: [SubredditPostsViewModel] = []
		subscriptions.forEach {
			if $0.model!.postCount > 0 {
				availableSubscriptions.append($0)
			} else {
				unavailableSubscriptions.append($0)
			}
		}
		return List {
			if totalPostCount > 0 {
				SectionVibrant(label: "Collections") {
					SubredditListEntry(subscription: .global, postCount: totalPostCount)
				}
			}
			if !availableSubscriptions.isEmpty {
				SubredditsSubscriptionsSection(header: "Subreddits", subscriptions: availableSubscriptions)
			}
			if !unavailableSubscriptions.isEmpty {
				SubredditsSubscriptionsSection(header: "Unavailable", subscriptions: unavailableSubscriptions)
			}
		}
			.navigationBarItems(trailing: Group {
				if !inSplitView {
					Button(action: {
						self.showAddSubreddits = true
					}) {
						Image(systemName: "plus")
							.font(.title)
							.frame(height: 44)
							.padding(.horizontal, 16)
					}
						.padding(.trailing, -16)
				}
			})
			.sheet(isPresented: $showAddSubreddits) {
				SubredditsManageSheet(subscriptions: self.subscriptions, subredditSearch: self.subredditSearch)
					.accentColor(.tint)
					.environment(\.managedObjectContext, self.context)
			}
			.onAppear {
				SubredditUserModel.shared.selected = nil
				if !self.inSplitView && self.subscriptions.isEmpty {
					self.showAddSubreddits = true
				}
			}
	}
}

private struct SubredditsSubscriptionsSection: View {
	let header: String
	let subscriptions: [SubredditPostsViewModel]

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		SectionVibrant(label: header) {
			ForEach(self.subscriptions) { subreddit in
				SubredditListEntry(subscription: subreddit, postCount: nil)
			}
				.onDelete { indices in
					self.subscriptions.performDelete(at: indices, from: self.context)
				}
		}
	}
}

private struct SubredditListEntry: View {
	let subscription: SubredditPostsViewModel
	let postCount: Int

	init(subscription: SubredditPostsViewModel, postCount: Int? = nil) {
		self.subscription = subscription
		self.postCount = postCount ?? subscription.model!.postCount
	}

	var body: some View {
		HStack {
			Button(action: {
				SubredditUserModel.shared.selected = self.subscription
			}) {
				SubredditTitle(name: subscription.model?.name)
					.font(.system(size: 21))
					.padding(.vertical)
			}
			Spacer()
			if subscription.model != nil {
				PriorityButton(subreddit: subscription.model!, size: 8, tooltip: true)
			}
			Text(postCount.description)
				.foregroundColor(.background)
				.font(.system(size: 17, weight: .bold))
				.frame(minWidth: 18)
				.lineLimit(1)
				.fixedSize()
				.padding(.vertical, 2)
				.padding(.horizontal, 3)
				.background(
					Capsule()
						.fill(Color.secondary)
				)
				.hidden(postCount == 0)
		}
	}
}

struct SubredditsView_Previews: PreviewProvider {
	private static let context = CoreDataModel().persistentContainer.viewContext

	static var previews: some View {
		SubredditsView(subscriptions: [], inSplitView: false)
			.environment(\.managedObjectContext, context)
	}
}
