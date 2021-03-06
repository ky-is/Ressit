import SwiftUI

struct BrowseView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<UserSubreddit>

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		let subscriptionViewModels = subscriptions.map { SubredditPostsViewModel(model: $0, in: context) }
		return NavigationView {
			SubredditsView(subscriptions: subscriptionViewModels)
			SubredditPostsView(subscription: .global)
			SubredditPostView(post: nil)
		}
	}
}

struct BrowseView_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext

	static var previews: some View {
		BrowseView()
			.environment(\.managedObjectContext, context)
	}
}
