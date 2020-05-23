import SwiftUI

struct BrowseView: View {
	var body: some View {
		GeometryReader { geometry in
			if geometry.size.width > 640 {
				HStack(spacing: 0) {
					BrowseSidebar(geometry: geometry)
						.navigationViewStyle(StackNavigationViewStyle())
					Divider()
						.padding(.top, -64)
					SubredditsView(isChild: true)
						.navigationViewStyle(StackNavigationViewStyle())
				}
			} else {
				SubredditsView(isChild: false)
			}
		}
	}
}

struct BrowseSidebar: View {
	let geometry: GeometryProxy

	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<SubredditSubscriptionModel>
	@ObservedObject private var userModel = UserModel.shared

	private let subredditSearch = SubredditsSearchViewModel()

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions.map({ SubredditPostsViewModel(model: $0) }), subredditSearch: subredditSearch)
				.edgesIgnoringSafeArea(.horizontal)
				.onAppear {
					UserModel.shared.selectedSubreddit = nil
				}
				.background(
					SelectedSubredditLink(isChild: false)
				)
		}
			.frame(maxWidth: min(geometry.size.width / 2.5, 320))
	}
}

struct SelectedSubredditLink: View {
	let isChild: Bool

	@ObservedObject private var userModel = UserModel.shared

	var body: some View {
		NavigationLink(
			destination:
				SubredditView(subscription: userModel.selectedSubreddit ?? .global)
					.navigationBarBackButtonHidden(isChild)
			,
			isActive: .constant(userModel.selectedSubreddit != nil)
		) {
			EmptyView()
		}
			.hidden()
	}
}

struct BrowseView_Previews: PreviewProvider {
	static var previews: some View {
		BrowseView()
	}
}
