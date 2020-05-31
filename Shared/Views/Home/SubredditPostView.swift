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
	private let imageViewModel: ImageDownloadManager?
	@State private var fullscreenImage: UIImage?

	init(post: UserPost) {
		self.post = post
		if let latest = SubredditPostCommentsViewModel.latest, latest.id == post.id {
			self.commentsViewModel = latest
		} else {
			self.commentsViewModel = SubredditPostCommentsViewModel(post: post)
		}
		if let previewURL = post.previewURL {
			self.imageViewModel = ImageDownloadManager(url: previewURL)
		} else {
			self.imageViewModel = nil
		}
	}

	var body: some View {
		List {
			VStack(spacing: 0) {
				SubredditPostHeader(post: post)
				if post.previewURL != nil {
					if post.previewIsVideo {
						PostVideo(url: post.previewURL!, aspectRatio: post.previewHeight > 0 ? CGFloat(post.previewWidth / post.previewHeight) : 16/9)
					} else {
						DownloadImageView(viewModel: imageViewModel!)
							.background(Color.background)
							.frame(maxWidth: .infinity)
							.aspectRatio(CGFloat(post.previewWidth / post.previewHeight), contentMode: .fill)
							.onTapGesture {
								if case let .success(image) = self.imageViewModel?.state {
									self.fullscreenImage = image
								}
							}
					}
				}
			}
				.fixedSize(horizontal: false, vertical: true)
				.listRowInsets(.zero)
			SubredditPostBody(post: post, commentsViewModel: commentsViewModel)
		}
			.overlay(Group {
				if fullscreenImage != nil {
					GeometryReader { geometry in
						ScrollImageView(image: self.fullscreenImage!, width: CGFloat(self.post.previewWidth), height: CGFloat(self.post.previewHeight), geometry: geometry)
							.edgesIgnoringSafeArea(.bottom)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.background(Color.background.edgesIgnoringSafeArea(.all))
							.onTapGesture {
								self.fullscreenImage = nil
							}
					}
				}
			})
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
	let post: UserPost

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
			if post.selftext?.nonEmpty != nil {
				Divider()
					.padding(.top)
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

#if DEBUG
struct SubredditPostView_Previews: PreviewProvider {
	static let post = UserPost(post: RedditListing<RedditPost>(asset: .posts).values.first!, insertInto: CoreDataModel.persistentContainer.viewContext)

	static var previews: some View {
		NavigationView {
			SubredditPostView(post: post)
		}
	}
}
#endif
