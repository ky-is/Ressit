import AuthenticationServices
import UIKit
import SwiftUI

var globalPresentationAnchor: ASPresentationAnchor?

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	var coreDataModel: CoreDataModel?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		let coreDataModel = CoreDataModel()
		self.coreDataModel = coreDataModel
		let contentView = ContentView().environment(\.managedObjectContext, coreDataModel.persistentContainer.viewContext)
		if let windowScene = scene as? UIWindowScene {
			let window = UIWindow(windowScene: windowScene)
			window.rootViewController = UIHostingController(rootView: contentView)
			self.window = window
			window.makeKeyAndVisible()
			globalPresentationAnchor = window
		}
	}

	func sceneWillResignActive(_ scene: UIScene) {
		coreDataModel?.saveIfNeeded()
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		RedditAuthManager.refreshIfNeeded()
	}
}
