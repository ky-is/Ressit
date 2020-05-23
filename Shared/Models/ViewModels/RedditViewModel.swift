import Foundation
import Combine

protocol RedditViewModel: ObservableObject {
	associatedtype NetworkResource: RedditResponsable

	var objectWillChange: ObservableObjectPublisher { get }
	var request: APIRequest<NetworkResource>? { get set }
	var subscription: AnyCancellable? { get set }
	var loading: Bool { get set }
	var error: Error? { get set }
	var result: NetworkResource? { get set }

	func fetch()
	func fetch(_: APIRequest<NetworkResource>, callback: ((NetworkResource) -> Void)?)
}

extension RedditViewModel {
	func fetch() {
		guard let request = request ?? self.request else {
			return
		}
		fetch(request)
	}

	func fetch(_ request: APIRequest<NetworkResource>, callback: ((NetworkResource) -> Void)? = nil) {
		guard subscription == nil else {
			return
		}
		self.request = request
		loading = true
		subscription = RedditClient.shared.send(request)
			.receive(on: RunLoop.main)
			.sink(receiveCompletion: { completion in
				self.subscription = nil
				self.loading = false
				switch completion {
				case .failure(let error):
					print(error)
					self.error = error
				case .finished:
					break
				}
				self.objectWillChange.send()
			}, receiveValue: { result in
				self.result = result
				callback?(result)
			})
	}
}
