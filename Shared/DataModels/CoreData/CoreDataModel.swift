import CoreData

struct CoreDataModel {
	static var persistentContainer: NSPersistentCloudKitContainer = {
		let container = NSPersistentCloudKitContainer(name: "CoreData")
		container.loadPersistentStores { storeDescription, error in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
			container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
			container.viewContext.automaticallyMergesChangesFromParent = true
//#if DEBUG
//			try! container.viewContext.execute(NSBatchDeleteRequest(fetchRequest: SubredditPostMetadataModel.fetchRequest())) //SAMPLE
//#endif
		}
		return container
	}()

	static func saveContext() {
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
