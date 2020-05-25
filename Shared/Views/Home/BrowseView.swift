import SwiftUI

struct BrowseView: View {
	@ObservedObject private var subredditUserModel = SubredditUserModel.shared

	var body: some View {
		GeometryReader { geometry in
//			if geometry.size.width > 900 { //SAMPLE
			if geometry.size.width > 640 {
				SplitView(contentWidth: geometry.size.width / 2)
			} else {
				SubredditsView(inSplitView: false)
			}
		}
	}
}

struct SplitView: View {
	let contentWidth: CGFloat

	var body: some View {
		HStack(spacing: 0) {
			SubredditsView(inSplitView: true)
			Divider()
				.padding(.top, -32)
			BrowseSidebar()
				.frame(width: contentWidth)
		}
	}
}

struct BrowseSidebar: View {
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
					SelectedPostLink(inSplitView: true)
				)
		}
			.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct SelectedSubredditLink: View {
	let inSplitView: Bool

	@ObservedObject private var subredditUserModel = SubredditUserModel.shared

	var body: some View {
		HiddenNavigationLink(
			isActive: subredditUserModel.selected != nil,
			destination: SubredditPostsView(subscription: subredditUserModel.selected ?? .global, inSplitView: inSplitView)
		)
	}
}

struct SelectedPostLink: View {
	let inSplitView: Bool

	@ObservedObject private var postUserModel = PostUserModel.shared
	@ObservedObject private var subredditUserModel = SubredditUserModel.shared

	var body: some View {
		HiddenNavigationLink(
			isActive: inSplitView ? subredditUserModel.selected != nil || postUserModel.selected != nil : postUserModel.selected != nil,
			destination: SubredditPostView(post: postUserModel.selected).navigationBarBackButtonHidden(inSplitView)
		)
	}
}

struct BrowseView_Previews: PreviewProvider {
	static var previews: some View {
		BrowseView()
	}
}
