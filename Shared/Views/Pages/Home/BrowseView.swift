import SwiftUI

struct BrowseView: View {
	@FetchRequest(sortDescriptors: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))], animation: .default) private var subscriptions: FetchedResults<UserSubreddit>

	@Environment(\.managedObjectContext) private var context

	var body: some View {
		let subscriptionViewModels = subscriptions.map { SubredditPostsViewModel(model: $0, in: context) }
		return GeometryReader { geometry in
//			if geometry.size.width > 900 { //SAMPLE
			if geometry.size.width > 640 {
				SplitView(subscriptions: subscriptionViewModels, contentWidth: geometry.size.width / 2)
			} else {
				SubredditsView(subscriptions: subscriptionViewModels, inSplitView: false)
			}
		}
	}
}

struct SplitView: View {
	let subscriptions: [SubredditPostsViewModel]
	let contentWidth: CGFloat

	var body: some View {
		HStack(spacing: 0) {
			SubredditsView(subscriptions: subscriptions, inSplitView: true)
			Divider()
				.padding(.top, -32)
			BrowseSidebar(subscriptions: subscriptions)
				.frame(width: contentWidth)
		}
	}
}

struct BrowseSidebar: View {
	let subscriptions: [SubredditPostsViewModel]

	var body: some View {
		NavigationView {
			SubredditsManage(subscriptions: subscriptions, subredditSearch: SubredditsSearchViewModel())
				.edgesIgnoringSafeArea(.horizontal)
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
			isActive: $subredditUserModel.isActive,
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
			isActive: inSplitView ? $subredditUserModel.isActive : $postUserModel.isActive,
			destination:
				SubredditPostView(post: postUserModel.selected)
					.navigationBarBackButtonHidden(inSplitView)
		)
	}
}

struct BrowseView_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext

	static var previews: some View {
		BrowseView()
			.environment(\.managedObjectContext, context)
	}
}
