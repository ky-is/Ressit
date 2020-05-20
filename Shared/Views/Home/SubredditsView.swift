import Combine
import SwiftUI

struct SubredditsView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SubredditSubscription.name, ascending: true)], animation: .default) private var subreddits: FetchedResults<SubredditSubscription>

	var body: some View {
		Group {
			if subreddits.isEmpty {
				SubredditSearch()
					.navigationBarTitle("Add Subreddit")
			} else {
				SubredditsList(subreddits: subreddits)
					.navigationBarTitle("Subreddits")
			}
		}
	}
}

private struct SubredditSearch: View {
	@State private var searchText = ""

	var body: some View {
		VStack {
			SearchBar(text: $searchText, autoFocus: true)
			Spacer()
			Text("No subscriptions")
			Spacer()
		}
	}
}

private struct SubredditsList: View {
	let subreddits: FetchedResults<SubredditSubscription>

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
