import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditView: View {
	@ObservedObject var subscription: SubredditPostsViewModel

	var body: some View {
		LocalView(subscription, sortDescriptor: postSort, predicate: NSPredicate(format: "subreddit = %@", subscription.model)) { (result: FetchedResults<SubredditPostModel>) in
			SubredditPostsList(posts: result)
		}
			.navigationBarTitle("r/\(subscription.model.name)")
	}
}

struct AllSubredditPostsView: View {
	@FetchRequest(sortDescriptors: [postSort]) private var fetchedResults: FetchedResults<SubredditPostModel>

	var body: some View {
		SubredditPostsList(posts: fetchedResults)
			.navigationBarTitle("All")
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
