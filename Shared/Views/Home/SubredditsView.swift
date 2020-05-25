import Combine
import SwiftUI

struct SubredditsView: View {
	let inSplitView: Bool

	var body: some View {
		NavigationView {
			SubredditsContainer(inSplitView: inSplitView)
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
	let inSplitView: Bool

	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<SubredditSubscriptionModel>
	@Environment(\.managedObjectContext) private var context
	private let subredditSearch = SubredditsSearchViewModel()

	var body: some View {
		let subscriptionViewModels = subscriptions.map { SubredditPostsViewModel(model: $0) }
		subscriptionViewModels.forEach { $0.updateIfNeeded(in: self.context) }
		return SubredditsSubscriptionList(subscriptions: subscriptionViewModels, subredditSearch: subredditSearch, inSplitView: inSplitView)
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
		List {
			SubredditListEntry(subscription: .global, postCount: subscriptions.reduce(0, +, \.model!.postCount))
			ForEach(subscriptions) { subreddit in
				SubredditListEntry(subscription: subreddit, postCount: nil)
			}
				.onDelete { indices in
					self.subscriptions.delete(at: indices, from: self.context)
				}
		}
			.navigationBarItems(trailing: Group {
				if !inSplitView {
					Button(action: {
						self.showAddSubreddits = true
					}) {
						Text("＋")
							.font(.title)
					}
				}
			})
			.sheet(isPresented: $showAddSubreddits) {
				SubredditsManageSheet(subscriptions: self.subscriptions, subredditSearch: self.subredditSearch)
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

private struct SubredditListEntry: View {
	let subscription: SubredditPostsViewModel
	let postCount: Int?

	var body: some View {
		HStack {
			Button(action: {
				SubredditUserModel.shared.selected = self.subscription
			}) {
				SubredditTitle(name: subscription.model?.name)
			}
			Spacer()
			Text((postCount ?? subscription.model!.postCount).description)
				.foregroundColor(.background)
				.font(Font.footnote.bold())
				.padding(4)
				.background(
					Circle()
						.fill(Color.secondary)
				)
		}
	}
}

private struct SubredditsManageSheet: View {
	let subscriptions: [SubredditPostsViewModel]
	let subredditSearch: SubredditsSearchViewModel

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions, subredditSearch: subredditSearch)
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

struct SubredditsManage: View {
	let subscriptions: [SubredditPostsViewModel]
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
			.navigationBarTitle(Text("Subscriptions"), displayMode: .inline)
	}
}

private struct SubredditsResponseList<VM: RedditViewModel>: View where VM.NetworkResource == RedditListing<Subreddit> {
	let viewModel: VM
	let subscriptions: [SubredditPostsViewModel]

	var body: some View {
		RedditView(viewModel) { result in
			List(result.values) { subreddit in
				SubredditsManageEntry(subreddit: subreddit, subscriptionModel: self.subscriptions.first { $0.model!.id == subreddit.id }?.model)
			}
		}
	}
}

private struct SubredditsManageEntry: View {
	let subreddit: Subreddit
	let subscriptionModel: SubredditSubscriptionModel?

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Button(action: {
			self.context.perform {
				if let subscriptionModel = self.subscriptionModel {
					self.context.delete(subscriptionModel)
				} else {
					SubredditSubscriptionModel.create(for: self.subreddit, in: self.context)
				}
				self.context.safeSave()
			}
		}) {
			HStack {
				Text(subscriptionModel != nil ? "✔︎" : "◯")
					.foregroundColor(subscriptionModel != nil ? .accentColor : .secondary)
					.frame(width: 16)
				SubredditTitle(name: subreddit.name)
			}
		}
	}
}

struct SubredditsView_Previews: PreviewProvider {
	static var previews: some View {
		SubredditsView(inSplitView: false)
			.environment(\.managedObjectContext, CoreDataModel.persistentContainer.viewContext)
	}
}
