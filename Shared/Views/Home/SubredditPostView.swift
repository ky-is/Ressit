import SwiftUI

private let postSort = NSSortDescriptor(key: "score", ascending: false)

struct SubredditPostView: View {
	let post: SubredditPostModel?

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
	let post: SubredditPostModel

	private let commentsViewModel: SubredditPostCommentsViewModel

	init(post: SubredditPostModel) {
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
						DownloadImageView(viewModel: ImageDownloadManager(id: "", url: post.previewURL!, cache: false))
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
	@ObservedObject var post: SubredditPostModel

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
					HStack(spacing: 1) {
						Text("👤")
						Text(post.author)
					}
					HStack(spacing: 1) {
						Text("🗓")
						Text(post.creationDate?.relativeToNow ?? "")
					}
					SubredditTitle(name: post.subreddit.name)
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
		let post = SubredditPostModel(context: CoreDataModel.persistentContainer.viewContext)
		post.title = "Test"
		post.author = "Tester"
		post.commentCount = 42
		post.creationDate = Date(timeIntervalSinceNow: -.month)
		return NavigationView {
			SubredditPostView(post: post)
		}
	}
}
