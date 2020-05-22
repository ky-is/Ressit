import Combine
import SwiftUI

struct SubredditsView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<SubredditSubscription>

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
						.font(.title)
				}
			)
			.sheet(isPresented: $showAddSubreddits) {
				SubredditsManageSheet(subscriptions: self.subscriptions)
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

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: self.subscriptions)
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

final class SearchViewModel: ObservableObject {
	@Published var query = ""
	@Published var results: [Subreddit]?

	private var subscription: AnyCancellable?

	init() {
		subscription = $query
			.setFailureType(to: Error.self)
			.removeDuplicates()
			.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
			.map { $0.starts(with: "r/") ? String($0.dropFirst(2)) : $0 }
			.filter { $0.count > 2 }
			.flatMap { query in RedditClient.shared.send(.subreddits(search: query)) }
			.map { response -> [Subreddit]? in response.values }
			.replaceError(with: nil)
			.assign(to: \.results, on: self)
	}
}

private struct SubredditsManage: View {
	let subscriptions: FetchedResults<SubredditSubscription>

	@ObservedObject private var search = SubredditsSearchViewModel()

	var body: some View {
		ZStack(alignment: .top) {
			VStack(spacing: 0) {
				SearchBar(text: $search.query, autoFocus: false)
				Group {
					if search.result?.values != nil {
						RedditView(search) { result in
							SubredditsSubscriptionListView(subreddits: result.values, subscriptions: self.subscriptions)
						}
					} else if RedditAuthModel.shared.accessToken != nil {
						RedditView(SubredditsMineViewModel.shared) { result in
							SubredditsSubscriptionListView(subreddits: result.values, subscriptions: self.subscriptions)
						}
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

private struct SubredditsSubscriptionListView: View {
	let subreddits: [Subreddit]
	let subscriptions: FetchedResults<SubredditSubscription>

	var body: some View {
		List(subreddits) { subreddit in
			SubredditsManageEntry(subreddit: subreddit, subscription: self.subscriptions.first { $0.id == subreddit.id })
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
