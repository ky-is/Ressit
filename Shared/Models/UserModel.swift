import Combine

final class UserModel: ObservableObject {
	static let shared = UserModel()

	@Published var selectedSubreddit: SubredditPostsViewModel?
}
