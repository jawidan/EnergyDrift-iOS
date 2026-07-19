import FirebaseAnalytics
import Foundation

// This is the single branch-specific scenario file referenced in
// AGENT_SPEC_iOS.md §2. This branch (ios/firebase-11.0.0) adds the
// Firebase Analytics scenarios from §5.3.
enum BranchScenarios {
    static let all: [TestScenario] = [
        EventBatchScenario(),
        RichEventsScenario(),
        UserPropertiesScenario(),
        BackgroundSyncScenario(),
    ]
}

private func fixedEventParameters() -> [String: Any] {
    ["source": "energydrift", "value": 1]
}

private func richEventParameters(index: Int) -> [String: Any] {
    [
        "p0": "energydrift",
        "p1": index,
        "p2": "scenario",
        "p3": index * 2,
        "p4": "rich_events",
        "p5": index * 3,
        "p6": "fixed",
        "p7": index % 7,
        "p8": "deterministic",
        "p9": index + 100,
    ]
}

struct EventBatchScenario: TestScenario {
    let scenarioName = "event_batch"
    let libraryName = "Firebase Analytics"
    let libraryVersion = "11.0.0"
    let category = "analytics"

    func setUp() async throws {}

    func run() async throws -> IterationMetrics {
        for _ in 0..<100 {
            Analytics.logEvent("ed_event", parameters: fixedEventParameters())
        }
        return IterationMetrics(bytesTransferred: 0, itemsProcessed: 100)
    }

    func tearDown() async throws {}
}

struct RichEventsScenario: TestScenario {
    let scenarioName = "rich_events"
    let libraryName = "Firebase Analytics"
    let libraryVersion = "11.0.0"
    let category = "analytics"

    func setUp() async throws {}

    func run() async throws -> IterationMetrics {
        for index in 0..<50 {
            Analytics.logEvent("ed_rich_event", parameters: richEventParameters(index: index))
        }
        return IterationMetrics(bytesTransferred: 0, itemsProcessed: 50)
    }

    func tearDown() async throws {}
}

struct UserPropertiesScenario: TestScenario {
    let scenarioName = "user_properties"
    let libraryName = "Firebase Analytics"
    let libraryVersion = "11.0.0"
    let category = "analytics"

    func setUp() async throws {}

    func run() async throws -> IterationMetrics {
        for index in 0..<20 {
            Analytics.setUserProperty("value_\(index)", forName: "ed_property_\(index)")
        }
        for _ in 0..<50 {
            Analytics.logEvent("ed_event", parameters: fixedEventParameters())
        }
        return IterationMetrics(bytesTransferred: 0, itemsProcessed: 70)
    }

    func tearDown() async throws {}
}

struct BackgroundSyncScenario: TestScenario {
    let scenarioName = "background_sync"
    let libraryName = "Firebase Analytics"
    let libraryVersion = "11.0.0"
    let category = "analytics"

    func setUp() async throws {}

    func run() async throws -> IterationMetrics {
        for _ in 0..<100 {
            Analytics.logEvent("ed_event", parameters: fixedEventParameters())
        }
        try await Task.sleep(for: .seconds(60))
        return IterationMetrics(bytesTransferred: 0, itemsProcessed: 100)
    }

    func tearDown() async throws {}
}
