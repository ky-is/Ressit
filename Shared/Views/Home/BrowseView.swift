import SwiftUI

struct BrowseView: View {
	var body: some View {
		NavigationView {
			SubredditsView()
			AllSubredditPostsView()
		}
			.navigationViewStyle(DoubleColumnNavigationViewStyle())
	}
}

struct BrowseView_Previews: PreviewProvider {
	static var previews: some View {
		BrowseView()
	}
}
