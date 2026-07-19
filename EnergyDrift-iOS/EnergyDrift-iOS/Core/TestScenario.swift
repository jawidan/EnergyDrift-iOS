import Foundation

struct IterationMetrics {
    var bytesTransferred: Int = 0
    var itemsProcessed: Int = 0
}

protocol TestScenario {
    var scenarioName: String { get }
    var libraryName: String { get }
    var libraryVersion: String { get }
    var category: String { get }

    func setUp() async throws
    func run() async throws -> IterationMetrics
    func tearDown() async throws
}
