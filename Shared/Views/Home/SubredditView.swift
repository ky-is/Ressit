import SwiftUI

struct SubredditView: View {
	@ObservedObject var subreddit: SubredditSubscription

	var body: some View {
		List {
			Text("")
		}
			.navigationBarTitle("r/\(subreddit.name)")
	}
}

struct SubredditView_Previews: PreviewProvider {
	static var previews: some View {
		let subredditSubscription = SubredditSubscription(context: CoreDataModel.persistentContainer.viewContext)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return NavigationView {
			SubredditView(subreddit: subredditSubscription)
		}
	}
}
