import Combine
import UIKit

enum DownloadState {
	case loading, success(image: UIImage), failure(error: Error)
}

private enum DownloadError: Error {
	case invalidImage
}

final class ImageDownloadViewModel: ObservableObject {
	let url: URL
	private let localURL: URL?

	@Published var state: DownloadState

	private var subscription: AnyCancellable?
	private static let backgroundQueue = DispatchQueue.global(qos: .background)

	init(url: URL) {
		self.url = url
		self.localURL = nil
		self.state = .loading
		attemptDownload()
	}

	init<Object: RedditVotable>(url: URL, cacheFor object: Object, cacheName: String) {
		self.url = url
		self.localURL = object.cacheURL(for: url, name: cacheName)
		self.state = .loading
		if let localURL = localURL, FileManager.default.fileExists(atPath: localURL.path) {
//			try? FileManager.default.removeItem(at: localURL) //SAMPLE
			subscribe(to:
				Future<UIImage, DownloadError> { promise in
					if let image = UIImage(contentsOfFile: localURL.path) {
						promise(.success(image))
					} else {
						promise(.failure(.invalidImage))
						try? FileManager.default.removeItem(at: localURL)
					}
				}
					.subscribe(on: Self.backgroundQueue)
					.catch { _ in self.downloadPublisher }
					.receive(on: RunLoop.main)
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
			.tryMap { data, response in
				guard let image = UIImage(data: data) else {
					throw DownloadError.invalidImage
				}
				if let localURL = self.localURL {
					try? FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
					try? data.write(to: localURL)
				}
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
