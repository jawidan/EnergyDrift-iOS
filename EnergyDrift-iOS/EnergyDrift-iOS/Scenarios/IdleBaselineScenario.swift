import Foundation

struct IdleBaselineScenario: TestScenario {
    let scenarioName = "idle_baseline"
    let libraryName = "none"
    let libraryVersion = "0"
    let category = "baseline"

    func setUp() async throws {}

    func run() async throws -> IterationMetrics {
        try await Task.sleep(for: .seconds(2))
        return IterationMetrics(bytesTransferred: 0, itemsProcessed: 0)
    }

    func tearDown() async throws {}
}
