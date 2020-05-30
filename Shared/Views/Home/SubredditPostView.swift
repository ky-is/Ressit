import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostView: View {
	let post: UserPost?

	var body: some View {
		Group {
			if post != nil {
				SubredditPostContainer(post: post!)
			} else {
				EmptyView()
			}
		}
			.onDisappear {
				PostUserModel.shared.selected = nil
			}
	}
}

private struct SubredditPostContainer: View {
	let post: UserPost

	private let commentsViewModel: SubredditPostCommentsViewModel

	init(post: UserPost) {
		self.post = post
		if let latest = SubredditPostCommentsViewModel.latest, latest.id == post.id {
			self.commentsViewModel = latest
		} else {
			self.commentsViewModel = SubredditPostCommentsViewModel(post: post)
		}
	}

	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				SubredditPostHeader(post: post)
				if post.previewURL != nil {
					if post.previewIsVideo {
						PostVideo(url: post.previewURL!, aspectRatio: post.previewHeight > 0 ? CGFloat(post.previewWidth / post.previewHeight) : 16/9)
					} else {
						DownloadImageView(viewModel: ImageDownloadManager(url: post.previewURL!))
							.frame(maxWidth: .infinity)
					}
				}
			}
				.fixedSize(horizontal: false, vertical: true)
			SubredditPostBody(post: post, commentsViewModel: commentsViewModel)
		}
	}
}

private struct PostVideo: View {
	let url: URL
	@State var aspectRatio: CGFloat

	var body: some View {
		VideoViewer(url: url, aspectRatio: $aspectRatio)
			.aspectRatio(aspectRatio, contentMode: .fit)
			.frame(maxWidth: .infinity)
	}
}

private struct SubredditPostHeader: View {
	@ObservedObject var post: UserPost

	@State private var openLink = false

	var body: some View {
		VStack(spacing: 0) {
			VStack(alignment: .leading, spacing: 6) {
				Button(action: {
					self.openLink = true
				}) {
					Text(post.title)
						.font(.headline)
				}
				HStack {
					IconText(iconName: "person.fill", label: post.author)
					IconText(iconName: "calendar", label: post.creationDate?.relativeToNow ?? "")
					SubredditTitle(name: post.subreddit.name)
					if post.crosspostFrom != nil {
						Image(systemName: "link")
							.foregroundColor(.secondary)
						SubredditTitle(name: post.crosspostFrom!)
					}
					Spacer()
				}
					.font(.caption)
			}
			if post.selftext != nil {
				Divider()
					.padding(.vertical)
				Text(post.selftext!)
			}
		}
			.padding()
			.navigationBarTitle(Text(post.title), displayMode: .inline)
			.sheet(isPresented: $openLink) {
				SafariView(url: self.post.url!)
			}
	}
}

struct SubredditPostView_Previews: PreviewProvider {
	static var previews: some View {
		let post = UserPost(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.author = "Tester"
		post.commentCount = 42
		post.creationDate = Date(timeIntervalSinceNow: -.month)
		return NavigationView {
			SubredditPostView(post: post)
		}
	}
}
