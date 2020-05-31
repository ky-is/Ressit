import SwiftUI

struct ImageDownloadView: View {
	@ObservedObject var viewModel: ImageDownloadViewModel

	var body: some View {
		let image = getImage()
		return Group {
			if image != nil {
				Image(uiImage: image!)
					.renderingMode(.original)
					.resizable()
					.aspectRatio(contentMode: .fill)
			} else if getError() != nil {
				Text(getError()!.localizedDescription)
			} else {
				LoadingView()
			}
		}
			.onAppear(perform: viewModel.attemptDownload)
	}

	private func getError() -> Error? {
		guard case let .failure(error) = viewModel.state else {
			return nil
		}
		return error
	}

	private func getImage() -> UIImage? {
		guard case let .success(image) = viewModel.state else {
			return nil
		}
		return image
	}
}
