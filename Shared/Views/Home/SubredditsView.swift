import SwiftUI

struct SubredditsView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SubredditSubscription.name, ascending: true)], animation: .default) private var subreddits: FetchedResults<SubredditSubscription>
	@Environment(\.managedObjectContext) private var viewContext

	var body: some View {
		List {
			ForEach(subreddits, id: \.self) { subreddit in
				NavigationLink(destination: SubredditView(subreddit: subreddit)) {
					Text("r/\(subreddit.name)")
				}
			}
				.onDelete { indices in
					self.subreddits.delete(at: indices, from: self.viewContext)
				}
		}
			.navigationBarTitle("Subreddits")
	}
}

struct SubredditsView_Previews: PreviewProvider {
	static var previews: some View {
		SubredditsView()
			.environment(\.managedObjectContext, CoreDataModel.persistentContainer.viewContext)
	}
}
