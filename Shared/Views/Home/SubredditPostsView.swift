import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let inSplitView: Bool

	var body: some View {
		Group {
			if subscription.model != nil {
				OneSubredditPostsView(subscription: subscription, model: subscription.model!)
			} else {
				AllSubredditPostsView()
			}
		}
			.navigationBarTitle(Text(subscription.model != nil ? "r/\(subscription.model!.name)" : "Global Feed"), displayMode: .inline)
			.background(Group {
				if !inSplitView {
					SelectedPostLink(inSplitView: inSplitView)
				}
			})
	}
}

private struct OneSubredditPostsView: View {
	let subscription: SubredditPostsViewModel
	let model: SubredditSubscriptionModel

	var body: some View {
		LocalView(subscription, sortDescriptor: postSort, predicate: NSPredicate(format: "subreddit = %@", model)) { (result: FetchedResults<SubredditPostModel>) in
			SubredditPostsList(posts: result)
				.modifier(ClearReadModifier(model: self.model, posts: result))
		}
	}
}

private struct AllSubredditPostsView: View {
	@FetchRequest(sortDescriptors: [postSort]) private var fetchedResults: FetchedResults<SubredditPostModel>

	var body: some View {
		SubredditPostsList(posts: fetchedResults)
			.modifier(ClearReadModifier(model: nil, posts: fetchedResults))
	}
}

private struct SubredditPostsList: View {
	let posts: FetchedResults<SubredditPostModel>

	@ObservedObject private var postModel = PostUserModel.shared

	var body: some View {
		List(selection: $postModel.selected) {
			ForEach(posts) { post in
				SubredditPostListEntry(post: post)
					.tag(post)
			}
		}
			.onAppear {
				PostUserModel.shared.selected = nil
			}
	}
}

private struct ClearReadModifier: ViewModifier {
	let readPosts: [SubredditPostModel]
	let model: SubredditSubscriptionModel?

	@Environment(\.managedObjectContext) private var context

	init(model: SubredditSubscriptionModel?, posts: FetchedResults<SubredditPostModel>) {
		self.model = model
		self.readPosts = posts.filter { $0.metadata?.readDate != nil }
	}

	func body(content: Content) -> some View {
		content
			.navigationBarItems(trailing: Group {
				if !readPosts.isEmpty {
					Button(action: performDelete) {
						Text("Clear read")
					}
				}
			})
			.onDisappear {
				if !self.readPosts.isEmpty && PostUserModel.shared.selected == nil && SubredditUserModel.shared.selected == nil {
					self.performDelete()
				}
			}
	}

	private func performDelete() {
		context.perform {
			self.readPosts.forEach(self.context.delete)
			self.context.safeSave()
			if let model = self.model {
				self.context.refresh(model, mergeChanges: true)
			}
		}
	}
}

struct SubredditPostsView_Previews: PreviewProvider {
	static var previews: some View {
		let subredditSubscription = SubredditSubscriptionModel(context: CoreDataModel.persistentContainer.viewContext)
		subredditSubscription.name = "Test"
		subredditSubscription.creationDate = Date()
		return NavigationView {
			SubredditPostsView(subscription: SubredditPostsViewModel(model: subredditSubscription), inSplitView: false)
		}
	}
}
