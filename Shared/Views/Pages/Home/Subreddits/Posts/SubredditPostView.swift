import SwiftUI
import AVKit

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
	}
}

private struct SubredditPostContainer: View {
	let post: UserPost

	private let commentsViewModel: SubredditPostCommentsViewModel
	private let imageViewModel: ImageDownloadViewModel?
	@State private var fullscreenImage: UXImage?

	init(post: UserPost) {
		self.post = post
		if let latest = SubredditPostCommentsViewModel.latest, latest.id == post.id {
			self.commentsViewModel = latest
		} else {
			self.commentsViewModel = SubredditPostCommentsViewModel(post: post)
		}
		if let previewURL = post.previewURL {
			self.imageViewModel = ImageDownloadViewModel(url: previewURL)
		} else {
			self.imageViewModel = nil
		}
		post.updateAttributedString(sizeIncrease: 4)
	}

	var body: some View {
		GeometryReader { geometry in
			List {
				SubredditPostHeader(post: post)
					.fixedSize(horizontal: false, vertical: true)
					.modifier(PostListRowSwipeModifier(post: post))
				if post.previewURL != nil {
					Group {
						if post.previewIsVideo {
							PostVideo(url: post.previewURL!, aspectRatio: post.previewHeight > 0 ? CGFloat(post.previewWidth / post.previewHeight) : 16/9)
						} else if post.isYoutubeLink {
							YoutubeEmbedView(url: post.url!)
								.aspectRatio(16/9, contentMode: .fit)
								.frame(minHeight: 200)
						} else {
							ImageDownloadView(viewModel: imageViewModel!)
								.background(Color.background)
								.aspectRatio(CGFloat(post.previewWidth / post.previewHeight), contentMode: .fill)
								.onTapGesture {
									if case let .success(image) = imageViewModel?.state {
										fullscreenImage = image
									}
								}
						}
					}
						.frame(maxWidth: .infinity)
						.listRowInsets(.zero)
				}
				if post.body?.nonEmpty != nil {
					BodyText(entity: post, width: geometry.size.width - defaultListInset.leading * 2)
						.padding(.top, defaultListInset.top)
				}
				SubredditPostComments(post: post, commentsViewModel: commentsViewModel, width: geometry.size.width - defaultListInset.leading * 2)
			}
		}
			.overlay(PostImageOverlay(post: post, image: $fullscreenImage))
	}
}

private struct PostImageOverlay: View {
	let post: UserPost
	@Binding var image: UXImage?

	@State private var share = false

	var body: some View {
		Group {
			if image != nil {
				GeometryReader { geometry in
					ZStack(alignment: .bottom) {
						//TODO
//						ScrollImageView(image: image!, width: CGFloat(post.previewWidth), height: CGFloat(post.previewHeight), geometry: geometry)
//							.frame(maxWidth: .infinity, maxHeight: .infinity)
//							.background(Color.background.edgesIgnoringSafeArea(.all))
//							.onTapGesture {
//								image = nil
//							}
						ZStack(alignment: .top) {
//							BlurView(style: .systemChromeMaterial)
							HStack {
								Button {
									share = true
								} label: {
									Image(systemName: "square.and.arrow.up")
										.frame(minWidth: 44, maxHeight: .infinity)
								}
							}
								.frame(height: 44)
								.font(.system(size: 20))
						}
							.frame(height: 44 + geometry.safeAreaInsets.bottom)
					}
				}
					.edgesIgnoringSafeArea(.all)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.sheet(isPresented: $share) {
//						ShareSheet(activityItems: [image!]) //TODO
					}
			}
		}
	}
}

private struct PostVideo: View {
	let url: URL
	@State var aspectRatio: CGFloat

	var body: some View {
		Group {
			#if os(iOS)
			VideoViewer(url: url, aspectRatio: $aspectRatio)
				.aspectRatio(aspectRatio, contentMode: .fit)
				.frame(maxWidth: .infinity)
			#else
			VideoPlayer(player: AVPlayer(url: url))
			#endif
		}
	}
}

private struct LinkView: View {
	let title: String
	let url: URL

	@State private var openLink = false

	#if os(iOS)
	var body: some View {
		Button(title) {
			openLink = true
		}
			.sheet(isPresented: $openLink) {
				SafariView(url: url)
			}
	}
	#else
	var body: some View {
		Link(title, destination: url)
	}
	#endif
}

private struct SubredditPostHeader: View {
	let post: UserPost

	@State private var openLink = false

	var body: some View {
		Group {
			VStack(alignment: .leading, spacing: 0) {
				LinkView(title: post.title, url: post.url!)
					.font(.headline)
				if post.url?.host != nil {
					Text(post.url!.hostDescription!)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Label(post.author, systemImage: "person.fill")
							.labelStyle(FaintIconLabelStyle())
						RelativeIcon(since: post.creationDate)
						SubredditTitle(name: post.subreddit.name)
						if post.crosspostFrom != nil {
							Label {
								SubredditTitle(name: post.crosspostFrom!)
							} icon: {
								Image(systemName: "link")
							}
								.labelStyle(FaintIconLabelStyle())
						}
						SavedMetadata(entity: post)
					}
					HStack {
						HStack(spacing: 2) {
							ScoreMetadata(entity: post)
							if post.scoreProportion > 0 {
								Text("(\(Int(post.scoreProportion * 100))%)")
									.foregroundColor(.secondary)
							}
						}
						CommentsMetadata(post: post)
						AwardsMetadata(entity: post)
					}
						.font(Font.caption.monospacedDigit())
				}
					.font(.caption)
					.padding(.top, 6)
			}
		}
			.padding(.vertical, 8)
			.navigationTitle(post.title)
			.navigationBarTitleDisplayMode(.inline)
	}
}

#if DEBUG
struct SubredditPostView_Previews: PreviewProvider {
	private static let context = CoreDataModel.shared.persistentContainer.viewContext
	private static let post = UserPost(post: RedditListing<RedditPost>(asset: .posts).values.first!, insertInto: context)

	static var previews: some View {
		NavigationView {
			SubredditPostView(post: post)
		}
	}
}
#endif
