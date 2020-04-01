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
		let subreddit = SubredditSubscription.create(named: "Test", in: CoreDataModel.persistentContainer.viewContext)
		return NavigationView {
			SubredditView(subreddit: subreddit)
		}
	}
}
