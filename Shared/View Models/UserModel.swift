import Combine

final class SubredditUserModel: ObservableObject {
	static let shared = SubredditUserModel()

	@Published var selected: SubredditPostsViewModel? {
		didSet {
			if selected != nil {
				isActive = true
			}
		}
	}

	@Published var isActive = false {
		didSet {
			if !isActive {
				selected = nil
			}
		}
	}
}

final class PostUserModel: ObservableObject {
	static let shared = PostUserModel()

	@Published var selected: UserPost? {
		didSet {
			if selected != nil {
				isActive = true
			}
		}
	}

	@Published var isActive = false {
		didSet {
			if !isActive {
				selected = nil
			}
		}
	}
}
