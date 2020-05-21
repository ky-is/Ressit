import Combine
import SwiftUI

struct SubredditsView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SubredditSubscription.name, ascending: true)], animation: .default) private var subscriptions: FetchedResults<SubredditSubscription>

	var body: some View {
		SubredditsSubscriptionList(subscriptions: subscriptions)
			.navigationBarTitle("Subreddits")
	}
}

private struct SubredditsSubscriptionList: View {
	let subscriptions: FetchedResults<SubredditSubscription>

	@State private var showAddSubreddits = false

	@Environment(\.managedObjectContext) private var viewContext

	var body: some View {
		List {
			ForEach(subscriptions, id: \.self) { subreddit in
				NavigationLink(destination: SubredditView(subreddit: subreddit)) {
					SubredditTitle(name: subreddit.name)
				}
			}
				.onDelete { indices in
					self.subscriptions.delete(at: indices, from: self.viewContext)
				}
		}
			.navigationBarItems(trailing:
				Button(action: {
					self.showAddSubreddits = true
				}) {
					Text("＋")
				}
			)
			.sheet(isPresented: $showAddSubreddits) {
				NavigationView {
					SubredditsManage(subscriptions: self.subscriptions)
						.navigationBarTitle("Manage")
				}
					.navigationViewStyle(StackNavigationViewStyle())
					.environment(\.managedObjectContext, self.viewContext)
			}
			.onAppear {
				if self.subscriptions.isEmpty {
					self.showAddSubreddits = true
				}
			}
	}
}

private struct SubredditsManage: View {
	let subscriptions: FetchedResults<SubredditSubscription>

	@State private var searchText = ""

	var body: some View {
		ZStack(alignment: .top) {
			VStack(spacing: 0) {
				SearchBar(text: $searchText, autoFocus: false)
				Group {
					if RedditAuthModel.shared.accessToken != nil {
						SubredditsManageList(subscriptions: subscriptions)
					} else {
						Spacer()
						Text("Sign in to choose from subreddits you already subscribe to")
						Spacer()
					}
				}
			}
		}
	}
}

private struct SubredditsManageList: View {
	let subscriptions: FetchedResults<SubredditSubscription>

	var body: some View {
		RedditView(SubredditsViewModel.shared) { subreddits in
			List {
				ForEach(subreddits.values) { subreddit in
					SubredditsManageEntry(subreddit: subreddit, subscription: self.subscriptions.first { $0.id == subreddit.id })
				}
			}
		}
	}
}

private struct SubredditsManageEntry: View {
	let subreddit: Subreddit
	let subscription: SubredditSubscription?

	@Environment(\.managedObjectContext) private var viewContext

	var body: some View {
		Button(action: {
			self.viewContext.perform {
				if let subscription = self.subscription {
					self.viewContext.delete(subscription)
					self.viewContext.safeSave()
				} else {
					SubredditSubscription.create(for: self.subreddit, in: self.viewContext)
				}
			}
		}) {
			HStack {
				Text(subscription != nil ? "✔︎" : "◯")
					.foregroundColor(subscription != nil ? .accentColor : .secondary)
				SubredditTitle(name: subreddit.name)
			}
		}
	}
}

private struct SubredditTitle: View {
	let name: String

	var body: some View {
		Text("r/")
			.foregroundColor(.secondary)
		+
		Text(name)
	}
}

struct SubredditsView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SubredditsView()
		}
			.environment(\.managedObjectContext, CoreDataModel.persistentContainer.viewContext)
	}
}
