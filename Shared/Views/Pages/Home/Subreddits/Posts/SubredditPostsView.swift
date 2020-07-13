import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostsView: View {
	let subscription: SubredditPostsViewModel

	var body: some View {
		Group {
			if subscription.model != nil {
				OneSubredditPostsView(subscription: subscription, model: subscription.model!)
			} else {
				AllSubredditPostsView()
			}
		}
			.navigationTitle(subscription.model != nil ? "r/\(subscription.model!.name)" : "Global Feed")
			.navigationBarTitleDisplayMode(.inline)
	}
}

private struct OneSubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let model: UserSubreddit

	var body: some View {
		LocalView(subscription, sortDescriptor: postSort, predicate: \UserPost.subreddit == model) { (result: FetchedResults<UserPost>) in
			Group {
				if result.isEmpty {
					EmptyPostsPlaceholder(subscription: subscription)
				} else {
					SubredditPostsList(subscription: subscription, posts: result)
						.modifier(ClearReadModifier(model: model, posts: result))
				}
			}
		}
	}
}

private struct UpcomingPostsRow: View {
	@ObservedObject var model: UserSubreddit

	var body: some View {
		let nextUpdate = model.nextUpdate
		return VStack(alignment: .center) {
			PriorityButton(subreddit: model, size: 16, tooltip: true)
			Group {
				if nextUpdate.date.timeIntervalSinceNow < 0 {
					Text("Update ready")
				} else {
					RelativeText("Next update for top \(nextUpdate.period.rawValue) in", since: nextUpdate.date)
				}
			}
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
			.frame(maxWidth: .infinity, minHeight: 128, alignment: .center)
	}
}

private struct EmptyPostsPlaceholder: View {
	let subscription: SubredditPostsViewModel

	var body: some View {
		Group {
			if subscription.model != nil {
				EmptyPostsPlaceholderContent(model: subscription.model!)
			} else {
				EmptyView()
			}
		}
	}
}

private struct EmptyPostsPlaceholderContent: View {
	@ObservedObject var model: UserSubreddit

	var body: some View {
		let nextPeriod = model.nextUpdate
		return VStack {
			Text("Next update for top:")
				.foregroundColor(.secondary)
			RelativeText(nextPeriod.period.rawValue, since: nextPeriod.date)
				.font(.headline)
			PriorityButton(subreddit: model, size: 16, tooltip: true)
			Text("Increase priority to get more posts")
		}
	}
}

private struct AllSubredditPostsView: View {
	@FetchRequest(sortDescriptors: [postSort]) private var fetchedResults: FetchedResults<UserPost>

	var body: some View {
		SubredditPostsList(subscription: nil, posts: fetchedResults)
			.modifier(ClearReadModifier(model: nil, posts: fetchedResults))
	}
}

private struct SubredditPostsList: View {
	let subscription: SubredditPostsViewModel?
	let posts: FetchedResults<UserPost>

	var body: some View {
		let hasSubredditContext = subscription != nil
		return List {
			ForEach(posts) { post in
				SubredditPostListEntry(post: post, hasSubredditContext: hasSubredditContext)
					.tag(post)
			}
			if subscription?.model != nil {
				UpcomingPostsRow(model: subscription!.model!)
			}
		}
	}
}

private struct ClearReadModifier: ViewModifier {
	let model: UserSubreddit?
	let hasUnread: Bool

	init(model: UserSubreddit?, posts: FetchedResults<UserPost>) {
		self.model = model
		self.hasUnread = posts.first { $0.metadata?.readDate != nil } != nil
	}

	func body(content: Content) -> some View {
		content
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button("Clear read", action: PostUserModel.shared.performDelete)
						.hidden(!hasUnread)
				}
			}
	}
}

struct SubredditPostsView_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext
	private static var subredditSubscription: UserSubreddit = {
		let subredditSubscription = UserSubreddit(context: context)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return subredditSubscription
	}()

	static var previews: some View {
		NavigationView {
			SubredditPostsView(subscription: SubredditPostsViewModel(model: subredditSubscription, in: context))
		}
			.environment(\.managedObjectContext, context)
	}
}
