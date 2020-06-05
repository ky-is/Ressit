import SwiftUI
import CoreData
import Combine

protocol RedditIdentifiable: Identifiable {
	var id: String { get }
	static var type: String { get }

	func fullName() -> String
}

extension RedditIdentifiable {
	func fullName() -> String {
		return "\(Self.type)_\(id)"
	}
}

protocol RedditVotable: RedditIdentifiable, ObservableObject {
	var body: String? { get set }
	var userVote: Int { get set }
	var userSaved: Bool { get set }
	var score: Int { get }
	var awardCount: Int { get }
	var saveSubscription: AnyCancellable? { get set }
	var voteSubscription: AnyCancellable? { get set }
	var attributedString: NSAttributedString? { get set }

	func voteColor() -> Color
	func cacheURL(for source: URL, name: String) -> URL
	func toggleVote(_ vote: Int, in context: NSManagedObjectContext)
	func performSaved(_ saved: Bool, in context: NSManagedObjectContext)
	func updateAttributedString(sizeIncrease: CGFloat, async: Bool)
}

private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!

extension RedditVotable {
	func cacheURL(for source: URL, name: String) -> URL {
		return cacheDirectory.appendingPathComponent(id).appendingPathComponent(name).appendingPathExtension(source.pathExtension)
	}

	func voteColor() -> Color {
		if userVote > 0 {
			return .orange
		}
		if userVote < 0 {
			return .blue
		}
		return .secondary
	}

	func toggleVote(_ vote: Int, in context: NSManagedObjectContext) {
		performRemoteUpdate(on: \.userVote, updateTo: vote, request: .vote(entity: self, vote: vote), in: context)
	}

	func performSaved(_ saved: Bool, in context: NSManagedObjectContext) {
		performRemoteUpdate(on: \.userSaved, updateTo: saved, request: .save(entity: self, enabled: saved), in: context)
	}

	private func performRemoteUpdate<Value>(on keyPath: ReferenceWritableKeyPath<Self, Value>, updateTo value: Value, request: APIRequest<EmptyReddit>, in context: NSManagedObjectContext) {
		let oldValue = self[keyPath: keyPath]
		saveSubscription?.cancel()
		context.perform {
			self[keyPath: keyPath] = value
			context.safeSave()
		}
		self.saveSubscription = RedditClient.shared.send(request)
			.sink(receiveCompletion: { completion in
				switch completion {
				case .failure(let error):
					print("Undo", keyPath, oldValue, error)
					context.perform {
						self[keyPath: keyPath] = oldValue
						context.safeSave()
					}
				case .finished:
					break
				}
			}, receiveValue: { _ in })
	}

	func updateAttributedString(sizeIncrease: CGFloat, async: Bool) {
		guard let body = body, body.starts(with: "<"), let data = body.data(using: .windowsCP1250) ?? body.data(using: .utf8) else {
			return
		}
		let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType:  NSAttributedString.DocumentType.html]
		do {
			let attributedString = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
			let systemFamily = UIFont.systemFont(ofSize: 12).familyName
			attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length), options: []) { attribute, range, stop in
				if let font = attribute as? UIFont {
					let descriptor = font.fontDescriptor.withFamily(systemFamily)
					let font = UIFont(descriptor: descriptor, size: font.pointSize + sizeIncrease)
					attributedString.addAttribute(.font, value: font, range: range)
				}
			}
			if async {
				DispatchQueue.main.async {
					self.attributedString = attributedString
				}
			} else {
				self.attributedString = attributedString
			}
		} catch {
			print(error)
			return
		}
	}
}
