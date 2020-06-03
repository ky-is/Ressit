import SwiftUI

struct SubredditsManageSheet: View {
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

	@State private var title = "Manage"

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
			.navigationBarTitle(Text("\(title) subreddits"), displayMode: .inline)
			.onAppear {
				if self.subscriptions.isEmpty {
					self.title = "Add"
				}
			}
	}
}

private struct SubredditsResponseList<VM: RedditViewModel>: View where VM.NetworkResource == RedditListing<RedditSubreddit> {
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
	let subreddit: RedditSubreddit
	let subscriptionModel: UserSubreddit?

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		Button(action: {
			self.context.perform {
				if let subscriptionModel = self.subscriptionModel {
					self.context.delete(subscriptionModel)
				} else {
					UserSubreddit.create(for: self.subreddit, in: self.context)
				}
				self.context.safeSave()
			}
		}) {
			HStack(alignment: .firstTextBaseline) {
				Image(systemName: subscriptionModel != nil ? "checkmark" : "circle")
					.font(Font.body.weight(subscriptionModel != nil ? .bold : .light))
					.foregroundColor(subscriptionModel != nil ? .accentColor : .secondary)
					.frame(width: 20)
				SubredditTitle(name: subreddit.name)
				Text(subreddit.subscribers + " members")
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
	}
}

struct SubredditsManage_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext

	static var previews: some View {
		SubredditsManage(subscriptions: [], subredditSearch: SubredditsSearchViewModel())
			.environment(\.managedObjectContext, context)
	}
}
