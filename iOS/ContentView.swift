import SwiftUI

struct ContentView: View {
	@ObservedObject private var redditAuth = RedditAuthModel.shared

	var body: some View {
		Group {
			if redditAuth.accessToken != nil {
				BrowseView()
			} else {
				WelcomeView()
			}
		}
			.accentColor(.tint)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
