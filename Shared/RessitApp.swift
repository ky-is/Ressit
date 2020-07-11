import SwiftUI

@main
struct RessitApp: App {
	var body: some Scene {
		RessitScene()
	}
}

struct RessitScene: Scene {
	@Environment(\.scenePhase) private var scenePhase

	init() {
		refresh()
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, CoreDataModel.shared.persistentContainer.viewContext)
		}
			.onChange(of: scenePhase) { newScenePhase in
				switch newScenePhase {
				case .background:
					CoreDataModel.shared.saveIfNeeded()
				case .active:
					refresh()
				case .inactive:
					break
				@unknown default:
					print(newScenePhase)
				}
			}
	}

	private func refresh() {
		RedditAuthManager.refreshIfNeeded()
		RelativeTimer.shared.update()
	}
}
