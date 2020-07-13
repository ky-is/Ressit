import Combine
import SwiftUI

struct SubredditsView: View {
	let subscriptions: [SubredditPostsViewModel]

	var body: some View {
		SubredditsSubscriptionList(subscriptions: subscriptions)
			.navigationTitle("Subreddits")
	}
}

private struct SubredditsSubscriptionList: View {
	let subscriptions: [SubredditPostsViewModel]

	@StateObject private var subredditSearch = SubredditsSearchViewModel()

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
//						.tag(SubredditPostsViewModel.global)
				}
			}
			if !availableSubscriptions.isEmpty {
				SubredditsSubscriptionsSection(header: "Available", subscriptions: availableSubscriptions)
			}
			if !unavailableSubscriptions.isEmpty {
				SubredditsSubscriptionsSection(header: "Upcoming", subscriptions: unavailableSubscriptions)
			}
		}
			.listStyle(SidebarListStyle())
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showAddSubreddits = true
					} label: {
						Image(systemName: "plus")
							.imageScale(.large)
					}
				}
			}
			.sheet(isPresented: $showAddSubreddits) {
				SubredditsManageSheet(subscriptions: subscriptions, subredditSearch: subredditSearch)
					.environment(\.managedObjectContext, context)
			}
			.onAppear {
				if subscriptions.isEmpty {
					showAddSubreddits = true
				}

				//SAMPLE
//				let samples = subscriptions.compactMap(\.model).filter(\.postCount, ==, 0)
//				print(samples.map(\.name))
//				samples.forEach { $0.periodWeekDate = Date(timeIntervalSinceNow: -(.day - .minute)) }
//				context.safeSave()
			}
	}
}

private struct SubredditsSubscriptionsSection: View {
	let header: String
	let subscriptions: [SubredditPostsViewModel]

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Section(header: Text(header)) {
			ForEach(subscriptions) { subreddit in
				SubredditListEntry(subscription: subreddit, postCount: nil)
			}
				.onDelete { indices in
					subscriptions.performDelete(at: indices, from: context)
				}
		}
	}
}

private struct SubredditListEntry: View {
	let subscription: SubredditPostsViewModel
	let postCount: Int?

	var body: some View {
		let activation = Binding {
			SubredditUserModel.shared.selected == subscription
		} set: { isActive in
			SubredditUserModel.shared.selected = isActive ? subscription : nil
		}
		return HStack {
			NavigationLink(destination: SubredditPostsView(subscription: subscription), isActive: activation) {
				SubredditTitle(name: subscription.model?.name)
					.font(Font.body.weight(.medium))
					.padding(.vertical)
			}
			Spacer()
			HStack(spacing: 2) {
				if subscription.model != nil {
					PriorityButton(subreddit: subscription.model!, size: 8, tooltip: true)
						.padding(2)
						.frame(maxHeight: .infinity)
				}
				SubredditEntryLabel(subscription: subscription, postCount: postCount)
			}
		}
	}
}

private struct SubredditEntryLabel: View {
	let subscription: SubredditPostsViewModel
	let postCount: Int?

	var body: some View {
		HStack {
			if subscription.model != nil {
				SubredditEntryDynamic(subscription: subscription, subreddit: subscription.model!)
			} else if postCount != nil {
				SubredditEntryPostCount(count: postCount!)
			}
		}
			.font(.system(size: 17))
			.frame(width: 40, alignment: .trailing)
	}
}

private struct SubredditEntryDynamic: View {
	let subscription: SubredditPostsViewModel
	@ObservedObject var subreddit: UserSubreddit

	@Environment(\.managedObjectContext) private var context
	@Environment(\.font) private var font

	var body: some View {
		let postCount = subreddit.postCount
		return Group {
			if postCount > 0 {
				SubredditEntryPostCount(count: postCount)
			} else {
				RelativeText(since: subreddit.nextUpdate.date, atZero: {
					subscription.updateIfNeeded(in: context)
				})
					.foregroundColor(.secondary)
					.font(font?.weight(.semibold))
			}
		}
	}
}

private struct SubredditEntryPostCount: View {
	let count: Int

	var body: some View {
		Text(count.description)
			.fontWeight(.bold)
			.foregroundColor(.background)
			.frame(minWidth: 18)
			.lineLimit(1)
			.fixedSize()
			.padding(.vertical, 2)
			.padding(.horizontal, 3)
			.background(
				Capsule()
					.fill(Color.secondary)
			)
	}
}

struct SubredditsView_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext

	static var previews: some View {
		SubredditsView(subscriptions: [])
			.environment(\.managedObjectContext, context)
	}
}
