import SwiftUI

struct LoadingPlaceholder: View {
	let label: String
	let error: Error?
	let loadingHeight: CGFloat?

	private var content: some View {
		Group {
			if error != nil {
				Text(error!.localizedDescription)
			} else {
				ProgressView(label)
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
		LoadingPlaceholder(label: "test", error: nil, loadingHeight: 256)
	}
}
