import Combine
import SwiftUI

struct SubredditsView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<SubredditSubscription>

	let subredditSearch = SubredditsSearchViewModel()

	var body: some View {
		SubredditsSubscriptionList(subscriptions: subscriptions, subredditSearch: subredditSearch)
			.navigationBarTitle("Subreddits")
	}
}

private struct SubredditsSubscriptionList: View {
	let subscriptions: FetchedResults<SubredditSubscription>
	let subredditSearch: SubredditsSearchViewModel

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
						.font(.title)
				}
			)
			.sheet(isPresented: $showAddSubreddits) {
				SubredditsManageSheet(subscriptions: self.subscriptions, subredditSearch: self.subredditSearch)
					.environment(\.managedObjectContext, self.viewContext)
			}
			.onAppear {
				if self.subscriptions.isEmpty {
					self.showAddSubreddits = true
				}
			}
	}
}

private struct SubredditsManageSheet: View {
	let subscriptions: FetchedResults<SubredditSubscription>
	let subredditSearch: SubredditsSearchViewModel

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions, subredditSearch: subredditSearch)
				.navigationBarTitle("Manage")
				.navigationBarItems(trailing:
					Button(action: {
						self.presentationMode.wrappedValue.dismiss()
					}) {
						Text("Close")
					}
				)
		}
			.navigationViewStyle(StackNavigationViewStyle())
	}
}

private struct SubredditsManage: View {
	let subscriptions: FetchedResults<SubredditSubscription>
	@ObservedObject var subredditSearch: SubredditsSearchViewModel

	var body: some View {
		ZStack(alignment: .top) {
			VStack(spacing: 0) {
				SearchBar(text: $subredditSearch.query, autoFocus: false)
				Group {
					if subredditSearch.result?.values != nil {
						SubredditsResponseList(viewModel: subredditSearch, subscriptions: self.subscriptions)
					} else if RedditAuthModel.shared.accessToken != nil {
						SubredditsResponseList(viewModel: SubredditsMineViewModel.shared, subscriptions: self.subscriptions)
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

private struct SubredditsResponseList<VM: RedditViewModel>: View where VM.NetworkResource == RedditListing<Subreddit> {
	let viewModel: VM
	let subscriptions: FetchedResults<SubredditSubscription>

	var body: some View {
		RedditView(viewModel) { result in
			List(result.values) { subreddit in
				SubredditsManageEntry(subreddit: subreddit, subscription: self.subscriptions.first { $0.id == subreddit.id })
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
					.frame(width: 16)
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
