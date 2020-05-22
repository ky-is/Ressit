import SwiftUI

struct WelcomeView: View {
	@ObservedObject private var redditAuth = RedditAuthModel.shared

	var body: some View {
		NavigationView {
			VStack {
				Spacer()
				Text("Sign in to access your subscribed subreddits, enable upvoting/saving posts, and more.")
					.padding(.horizontal)
					.multilineTextAlignment(.center)
				Spacer()
				if redditAuth.loading {
					Text("⋯")
						.font(.largeTitle)
				} else {
					VStack(spacing: 20) {
						FillButton(label: "Sign In") {
							RedditAuthManager.signinIfNeeded()
						}
						FillButton(label: "Anonymous", backgroundColor: .gray) {
							RedditAuthManager.authorizeAnonymously()
						}
					}
				}
				Spacer()
			}
				.navigationBarTitle("ReddSS")
		}
			.navigationViewStyle(StackNavigationViewStyle())
	}
}

private struct FillButton: View {
	let label: String
	let backgroundColor: Color
	let action: () -> Void

	init(label: String, backgroundColor: Color = .accentColor, action: @escaping () -> Void) {
		self.label = label
		self.backgroundColor = backgroundColor
		self.action = action
	}

	var body: some View {
		Button(action: action) {
			Text(label)
				.font(.system(size: 26, weight: .semibold))
				.frame(minWidth: 256, minHeight: 64)
				.foregroundColor(.background)
				.background(backgroundColor)
				.cornerRadius(16)
		}
	}
}

struct WelcomeView_Previews: PreviewProvider {
	static var previews: some View {
		WelcomeView()
	}
}
