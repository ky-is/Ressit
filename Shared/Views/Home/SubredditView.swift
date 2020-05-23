import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditView: View {
	let subscription: SubredditPostsViewModel

	var body: some View {
		Group {
			if subscription.model != nil {
				OneSubredditPostsView(subscription: subscription, model: subscription.model!)
			} else {
				AllSubredditPostsView()
			}
		}
			.navigationBarTitle(Text(subscription.model != nil ? "r/\(subscription.model!.name)" : "Global Feed"), displayMode: .inline)
	}
}

private struct OneSubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let model: SubredditSubscriptionModel

	var body: some View {
		LocalView(subscription, sortDescriptor: postSort, predicate: NSPredicate(format: "subreddit = %@", model)) { (result: FetchedResults<SubredditPostModel>) in
			SubredditPostsList(posts: result)
		}
	}
}

private struct AllSubredditPostsView: View {
	@FetchRequest(sortDescriptors: [postSort]) private var fetchedResults: FetchedResults<SubredditPostModel>

	var body: some View {
		SubredditPostsList(posts: fetchedResults)
	}
}

private struct SubredditPostsList: View {
	let posts: FetchedResults<SubredditPostModel>

	var body: some View {
		List(posts) { post in
			NavigationLink(destination: SubredditPostView(post: post)) {
				VStack(alignment: .leading, spacing: 4) {
					Text(post.title)
						.font(.headline)
					HStack {
						Text("🔺") + Text(post.score.description)
						Text("💬") + Text(post.commentCount.description)
						Text("🕓") + Text(post.creationDate.relativeToNow)
					}
						.font(.caption)
				}
					.padding(.vertical, 6)
			}
		}
	}
}

struct SubredditView_Previews: PreviewProvider {
	static var previews: some View {
		let subredditSubscription = SubredditSubscriptionModel(context: CoreDataModel.persistentContainer.viewContext)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return NavigationView {
			SubredditView(subscription: SubredditPostsViewModel(model: subredditSubscription))
		}
	}
}
