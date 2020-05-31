import SwiftUI

struct LoadingView: View {
	var body: some View {
		Image(systemName: "ellipsis")
			.font(.largeTitle)
	}
}

struct LoadingPlaceholder: View {
	let error: Error?
	let loadingHeight: CGFloat?

	private var content: some View {
		Group {
			if error != nil {
				Text(error!.localizedDescription)
			} else {
				LoadingView()
			}
		}
		.frame(maxWidth: .infinity)
	}

	var body: some View {
		Group {
			if loadingHeight != nil {
				content
					.frame(minHeight: loadingHeight)
			} else {
				Spacer()
				content
				Spacer()
			}
		}
	}
}

struct LoadingViews_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			LoadingView()
			LoadingPlaceholder(error: nil, loadingHeight: 256)
		}
	}
}
