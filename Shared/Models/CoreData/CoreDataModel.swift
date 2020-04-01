import CoreData

struct CoreDataModel {
	static var persistentContainer: NSPersistentCloudKitContainer = {
		let container = NSPersistentCloudKitContainer(name: "ReddSS")
		container.loadPersistentStores() { (storeDescription, error) in
			container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
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
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
}
