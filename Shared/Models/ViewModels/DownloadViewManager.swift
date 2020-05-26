import Foundation
import Combine
import SwiftUI

enum DownloadState {
	case loading, success(image: UIImage), failure(error: Error)
}

enum DownloadError: Error {
	case invalidImage
}

final class ImageDownloadManager: ObservableObject {
	let id: String
	let url: URL

	@Published var state: DownloadState

	private let localURL: URL
	private var subscription: AnyCancellable?

	private static let localDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	private static let backgroundQueue = DispatchQueue.global(qos: .background)

	init(id: String, url: URL) {
		self.id = id
		self.url = url
		self.localURL = Self.localDirectory.appendingPathComponent(id + "/t").appendingPathExtension(url.pathExtension)
		try? FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
		self.state = .loading
		if FileManager.default.fileExists(atPath: localURL.path) {
			try? FileManager.default.removeItem(at: self.localURL) //SAMPLE
			subscribe(to:
				Future<UIImage, DownloadError> { promise in
					if let image = UIImage(contentsOfFile: self.localURL.path) {
						promise(.success(image))
					} else {
						promise(.failure(DownloadError.invalidImage))
						try? FileManager.default.removeItem(at: self.localURL)
					}
				}
					.subscribe(on: Self.backgroundQueue)
					.receive(on: RunLoop.main)
					.catch { error -> AnyPublisher<UIImage, Error> in
						self.state = .failure(error: error)
						return self.downloadPublisher
					}
					.eraseToAnyPublisher()
			)
		} else {
			attemptDownload()
		}
	}

	private func subscribe(to publisher: AnyPublisher<UIImage, Error>) {
		subscription?.cancel()
		subscription = publisher
			.sink(receiveCompletion: { completion in
				switch completion {
				case .failure(let error):
					print(error)
				case .finished:
					break
				}
				self.subscription = nil
			}) { result in
				self.state = .success(image: result)
			}
	}

	private var downloadPublisher: AnyPublisher<UIImage, Error> {
		URLSession.shared.dataTaskPublisher(for: url)
			.subscribe(on: Self.backgroundQueue)
			.receive(on: RunLoop.main)
			.tryMap { (data, response) in
				guard let image = UIImage(data: data) else {
					throw DownloadError.invalidImage
				}
				try data.write(to: self.localURL)
				return image
			}
			.eraseToAnyPublisher()
	}

	func attemptDownload() {
		guard subscription == nil else {
			return
		}
		if case .success(image: _) = state {
			return
		}
		subscribe(to: downloadPublisher)
	}
}

struct DownloadImageView: View {
	@ObservedObject var viewModel: ImageDownloadManager

	var body: some View {
		let image = getImage()
		return Group {
			if image != nil {
				Image(uiImage: image!)
					.renderingMode(.original)
					.resizable()
					.aspectRatio(contentMode: .fill)
			} else if isLoading() {
				Text("⋯")
					.font(.title)
			} else {
				Text(getError()?.localizedDescription ?? "✕")
			}
		}
			.onAppear(perform: viewModel.attemptDownload)
	}

	private func isLoading() -> Bool {
		guard case .loading = viewModel.state else {
			return true
		}
		return false
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
