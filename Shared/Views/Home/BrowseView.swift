import SwiftUI

struct BrowseView: View {
	var body: some View {
		GeometryReader { geometry in
//			if geometry.size.width > 900 { //SAMPLE
			if geometry.size.width > 640 {
				HStack(spacing: 0) {
					BrowseSidebar(geometry: geometry)
					Divider()
						.padding(.top, -64)
					SubredditsView(inSplitView: true)
				}
			} else {
				SubredditsView(inSplitView: false)
			}
		}
	}
}

struct BrowseSidebar: View {
	let geometry: GeometryProxy

	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<SubredditSubscriptionModel>

	private let subredditSearch = SubredditsSearchViewModel()

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions.map({ SubredditPostsViewModel(model: $0) }), subredditSearch: subredditSearch)
				.edgesIgnoringSafeArea(.horizontal)
				.onAppear {
					SubredditUserModel.shared.selected = nil
					PostUserModel.shared.selected = nil
				}
				.background(
					SelectedSubredditLink(inSplitView: true)
				)
		}
			.navigationViewStyle(StackNavigationViewStyle())
			.frame(maxWidth: min(geometry.size.width / 2.5, 320))
	}
}

struct SelectedSubredditLink: View {
	let inSplitView: Bool

	@ObservedObject private var subredditUserModel = SubredditUserModel.shared

	var body: some View {
		HiddenNavigationLink(
			isActive: subredditUserModel.selected != nil,
			destination: SubredditView(subscription: subredditUserModel.selected ?? .global, inSplitView: inSplitView)
		)
	}
}

struct SelectedPostLink: View {
	let inSplitView: Bool

	@ObservedObject private var postUserModel = PostUserModel.shared
	@ObservedObject private var subredditUserModel = SubredditUserModel.shared

	var body: some View {
		HiddenNavigationLink(
			isActive: inSplitView ? subredditUserModel.selected != nil : postUserModel.selected != nil,
			destination: SubredditPostView(post: postUserModel.selected).navigationBarBackButtonHidden(inSplitView)
		)
	}
}

struct BrowseView_Previews: PreviewProvider {
	static var previews: some View {
		BrowseView()
	}
}
