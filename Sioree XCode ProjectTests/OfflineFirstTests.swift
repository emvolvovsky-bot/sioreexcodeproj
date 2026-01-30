import Testing
@testable import Sioree_XCode_Project

struct OfflineFirstTests {

    @Test func coreDataStackLoads() async throws {
        // Ensure CoreData persistent container can be accessed without crashing
        let _ = CoreDataStack.shared.persistentContainer
        #expect(true).toBeTrue()
    }

}

