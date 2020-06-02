import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let inSplitView: Bool

	var body: some View {
		Group {
			if subscription.model != nil {
				OneSubredditPostsView(subscription: subscription, model: subscription.model!)
			} else {
				AllSubredditPostsView()
			}
		}
			.navigationBarTitle(Text(subscription.model != nil ? "r/\(subscription.model!.name)" : "Global Feed"), displayMode: .inline)
			.background(Group {
				if !inSplitView {
					SelectedPostLink(inSplitView: inSplitView)
				}
			})
	}
}

private struct OneSubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let model: UserSubreddit

	var body: some View {
		LocalView(subscription, sortDescriptor: postSort, predicate: \UserPost.subreddit == model) { (result: FetchedResults<UserPost>) in
			Group {
				if result.isEmpty {
					EmptyPostsPlaceholder(subscription: self.subscription)
				} else {
					SubredditPostsList(subscription: self.subscription, posts: result)
						.modifier(ClearReadModifier(model: self.model, posts: result))
				}
			}
				.onAppear {
					PostUserModel.shared.selected = nil
				}
		}
	}
}

private struct UpcomingPostsRow: View {
	@ObservedObject var model: UserSubreddit

	var body: some View {
		let nextPeriod = model.nextMostFrequentUpdate
		return VStack(alignment: .center) {
			PriorityButton(subreddit: model, size: 16, tooltip: true)
			Group {
				if nextPeriod.date.timeIntervalSinceNow < 0 {
					Text("Update ready")
				} else {
					RelativeText("Next update for top \(nextPeriod.period.rawValue) in", since: nextPeriod.date)
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
		List {
			ForEach(posts) { post in
				SubredditPostListEntry(post: post)
					.tag(post)
			}
			if subscription?.model != nil {
				UpcomingPostsRow(model: subscription!.model!)
			}
		}
	}
}

private struct ClearReadModifier: ViewModifier {
	let readPosts: [UserPost]
	let model: UserSubreddit?

	@Environment(\.managedObjectContext) private var context

	init(model: UserSubreddit?, posts: FetchedResults<UserPost>) {
		self.model = model
		self.readPosts = posts.filter { $0.metadata?.readDate != nil }
	}

	func body(content: Content) -> some View {
		content
			.navigationBarItems(trailing: Group {
				if !readPosts.isEmpty {
					Button(action: performDelete) {
						Text("Clear read")
					}
				}
			})
			.onDisappear {
				if !self.readPosts.isEmpty && PostUserModel.shared.selected == nil && SubredditUserModel.shared.selected == nil {
					self.performDelete()
				}
			}
	}

	private func performDelete() {
		PostUserModel.shared.selected = nil
		context.perform {
			self.readPosts.forEach(self.context.delete)
			self.context.safeSave()
			if let model = self.model {
				self.context.refresh(model, mergeChanges: true)
			}
		}
	}
}

struct SubredditPostsView_Previews: PreviewProvider {
	private static let context = CoreDataModel().persistentContainer.viewContext
	private static var subredditSubscription: UserSubreddit = {
		let subredditSubscription = UserSubreddit(context: context)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return subredditSubscription
	}()

	static var previews: some View {
		NavigationView {
			SubredditPostsView(subscription: SubredditPostsViewModel(model: subredditSubscription), inSplitView: false)
		}
			.environment(\.managedObjectContext, context)
	}
}
