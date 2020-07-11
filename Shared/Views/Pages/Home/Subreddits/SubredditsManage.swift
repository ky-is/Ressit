import SwiftUI

struct SubredditsManageSheet: View {
	let subscriptions: [SubredditPostsViewModel]
	let subredditSearch: SubredditsSearchViewModel

	@Environment(\.presentationMode) private var presentationMode

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions, subredditSearch: subredditSearch)
				//TODO
//				.navigationBarItems(trailing:
//					Button(action: {
//						presentationMode.wrappedValue.dismiss()
//					}) {
//						Text("Close")
//					}
//				)
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
				#if !os(macOS)
				SearchBar(text: $subredditSearch.query, autoFocus: false)
				#endif
				Group {
					if subredditSearch.result?.values != nil {
						SubredditsResponseList(viewModel: subredditSearch, subscriptions: subscriptions)
					} else if RedditAuthModel.shared.accessToken != nil {
						SubredditsResponseList(viewModel: SubredditsMineViewModel.shared, subscriptions: subscriptions)
					} else {
						Spacer()
						Text("Sign in to choose from subreddits you're subscribed to.")
							.font(.headline)
							.foregroundColor(.secondary)
							.padding()
							.multilineTextAlignment(.center)
						Spacer()
					}
				}
			}
		}
			.navigationTitle("\(title) subreddits")
			.onAppear {
				if subscriptions.isEmpty {
					title = "Add"
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
				SubredditsManageEntry(subreddit: subreddit, subscriptionModel: subscriptions.first { $0.model!.id == subreddit.id }?.model)
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
			context.perform {
				if let subscriptionModel = subscriptionModel {
					context.delete(subscriptionModel)
				} else {
					UserSubreddit.create(for: subreddit, in: context)
				}
				context.safeSave()
			}
		}) {
			HStack(alignment: .firstTextBaseline) {
				Image(systemName: subscriptionModel != nil ? "checkmark" : "circle")
					.font(Font.body.weight(subscriptionModel != nil ? .bold : .light))
					.foregroundColor(subscriptionModel != nil ? .accentColor : .secondary)
					.frame(width: 20)
				SubredditTitle(name: subreddit.name)
				Label(subreddit.subscribers, systemImage: "person.fill")
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
	}
}

struct SubredditsManage_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext
	private static var subredditSubscription: UserSubreddit = {
		let subredditSubscription = UserSubreddit(context: context)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return subredditSubscription
	}()
	private static let model = SubredditPostsViewModel(model: subredditSubscription, in: context)

	static var previews: some View {
		SubredditsManage(subscriptions: [model], subredditSearch: SubredditsSearchViewModel())
			.environment(\.managedObjectContext, context)
	}
}
