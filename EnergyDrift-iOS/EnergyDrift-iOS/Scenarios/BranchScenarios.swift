import Foundation
import SDWebImage

// This is the single branch-specific scenario file referenced in
// AGENT_SPEC_iOS.md §2. This branch (ios/sdwebimage-5.15.0) adds the
// SDWebImage image loading scenarios from §5.2.
enum BranchScenarios {
    static let all: [TestScenario] = [
        ColdLoadScenario(),
        WarmLoadScenario(),
        ConcurrentLoadScenario(),
        LargeImagesScenario(),
    ]
}

private func mockServerBaseURL() -> String {
    UserDefaults.standard.string(forKey: "mockServerBaseURL") ?? "http://192.168.1.100:5000"
}

/// 20 images mixing small/medium/large with unique cache-busting query strings.
private func imageURLList() -> [URL] {
    (1...20).map { id -> URL in
        let path: String
        switch id % 3 {
        case 0: path = "/image/small"
        case 1: path = "/image/medium"
        default: path = "/image/large"
        }
        return URL(string: mockServerBaseURL() + path + "?id=\(id)")!
    }
}

private func largeImageURLList() -> [URL] {
    (1...5).map { id in
        URL(string: mockServerBaseURL() + "/image/large?id=\(id)")!
    }
}

private func clearCaches() async {
    SDImageCache.shared.clearMemory()
    await withCheckedContinuation { continuation in
        SDImageCache.shared.clearDisk {
            continuation.resume()
        }
    }
}

@discardableResult
private func loadImage(_ url: URL) async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in
        SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { _, data, error, _, _, _ in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: data?.count ?? 0)
            }
        }
    }
}

struct ColdLoadScenario: TestScenario {
    let scenarioName = "cold_load"
    let libraryName = "SDWebImage"
    let libraryVersion = "5.15.0"
    let category = "image_loading"

    func setUp() async throws {
        await clearCaches()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for url in imageURLList() {
            bytes += try await loadImage(url)
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 20)
    }

    func tearDown() async throws {}
}

struct WarmLoadScenario: TestScenario {
    let scenarioName = "warm_load"
    let libraryName = "SDWebImage"
    let libraryVersion = "5.15.0"
    let category = "image_loading"

    func setUp() async throws {
        await clearCaches()
        for url in imageURLList() {
            _ = try await loadImage(url)
        }
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for url in imageURLList() {
            bytes += try await loadImage(url)
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 20)
    }

    func tearDown() async throws {}
}

struct ConcurrentLoadScenario: TestScenario {
    let scenarioName = "concurrent_load"
    let libraryName = "SDWebImage"
    let libraryVersion = "5.15.0"
    let category = "image_loading"

    func setUp() async throws {
        await clearCaches()
    }

    func run() async throws -> IterationMetrics {
        try await withThrowingTaskGroup(of: Int.self) { group in
            for url in imageURLList() {
                group.addTask {
                    try await loadImage(url)
                }
            }
            var bytes = 0
            for try await count in group {
                bytes += count
            }
            return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 20)
        }
    }

    func tearDown() async throws {}
}

struct LargeImagesScenario: TestScenario {
    let scenarioName = "large_images"
    let libraryName = "SDWebImage"
    let libraryVersion = "5.15.0"
    let category = "image_loading"

    func setUp() async throws {
        await clearCaches()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for url in largeImageURLList() {
            bytes += try await loadImage(url)
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 5)
    }

    func tearDown() async throws {}
}
