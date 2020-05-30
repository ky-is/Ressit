import Combine

final class SubredditUserModel: ObservableObject {
	static let shared = SubredditUserModel()

	@Published var selected: SubredditPostsViewModel?
}

final class PostUserModel: ObservableObject {
	static let shared = PostUserModel()

	@Published var selected: SubredditPostModel?
}
