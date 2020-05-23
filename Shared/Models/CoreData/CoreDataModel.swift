import CoreData

struct CoreDataModel {
	static var persistentContainer: NSPersistentCloudKitContainer = {
		let container = NSPersistentCloudKitContainer(name: "ReddSS")
		container.loadPersistentStores() { storeDescription, error in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
			container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		}
		return container
	}()

	static func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			context.safeSave()
		}
	}
}

extension NSManagedObjectContext {
	func safeSave() {
		do {
			try save()
		} catch {
			fatalError(error.localizedDescription)
		}
	}
}
