import AuthenticationServices
import UIKit
import SwiftUI

var globalPresentationAnchor: ASPresentationAnchor?

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		let context = CoreDataModel.persistentContainer.viewContext
		let contentView = ContentView().environment(\.managedObjectContext, context)
		if let windowScene = scene as? UIWindowScene {
			let window = UIWindow(windowScene: windowScene)
			window.rootViewController = UIHostingController(rootView: contentView)
			self.window = window
			window.makeKeyAndVisible()
			globalPresentationAnchor = window
		}
	}

	func sceneWillResignActive(_ scene: UIScene) {
		CoreDataModel.saveContext()
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		RedditAuthManager.refreshIfNeeded()
	}
}
