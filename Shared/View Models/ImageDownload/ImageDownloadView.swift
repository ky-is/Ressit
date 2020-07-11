import SwiftUI

struct ImageDownloadView: View {
	@ObservedObject var viewModel: ImageDownloadViewModel

	var body: some View {
		let image = getImage()
		return Group {
			if image != nil {
				Image(uxImage: image!)
					.renderingMode(.original)
					.resizable()
					.aspectRatio(contentMode: .fill)
			} else if getError() != nil {
				Text(getError()!.localizedDescription)
			} else {
				ProgressView("Image")
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

	private func getImage() -> UXImage? {
		guard case let .success(image) = viewModel.state else {
			return nil
		}
		return image
	}
}
