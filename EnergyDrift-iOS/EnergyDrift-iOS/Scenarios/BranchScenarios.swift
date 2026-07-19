import Alamofire
import Foundation

// This is the single branch-specific scenario file referenced in
// AGENT_SPEC_iOS.md §2. This branch (ios/alamofire-5.4.0) adds the
// Alamofire networking scenarios from §5.1.
enum BranchScenarios {
    static let all: [TestScenario] = [
        SequentialGetSmallScenario(),
        SequentialGetLargeScenario(),
        PostBatchScenario(),
        ConcurrentGetScenario(),
        ImageDownloadScenario(),
    ]
}

private func mockServerBaseURL() -> String {
    UserDefaults.standard.string(forKey: "mockServerBaseURL") ?? "http://192.168.1.100:5000"
}

private func makeRequest(path: String, method: HTTPMethod = .get, body: Data? = nil) -> URLRequest {
    var request = URLRequest(url: URL(string: mockServerBaseURL() + path)!)
    request.httpMethod = method.rawValue
    request.cachePolicy = .reloadIgnoringLocalCacheData
    if let body {
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return request
}

private func fetchData(_ request: URLRequest) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        AF.request(request).responseData { response in
            switch response.result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

private func makePostBody() -> Data {
    var payload = "AAAAAAAAAA"
    while payload.utf8.count < 900 {
        payload += payload
    }
    payload = String(payload.prefix(900))
    let object: [String: Any] = ["id": "energydrift", "payload": payload]
    return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
}

struct SequentialGetSmallScenario: TestScenario {
    let scenarioName = "sequential_get_small"
    let libraryName = "Alamofire"
    let libraryVersion = "5.4.0"
    let category = "networking"

    func setUp() async throws {
        URLCache.shared.removeAllCachedResponses()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for _ in 0..<50 {
            let data = try await fetchData(makeRequest(path: "/json/small"))
            bytes += data.count
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 50)
    }

    func tearDown() async throws {}
}

struct SequentialGetLargeScenario: TestScenario {
    let scenarioName = "sequential_get_large"
    let libraryName = "Alamofire"
    let libraryVersion = "5.4.0"
    let category = "networking"

    func setUp() async throws {
        URLCache.shared.removeAllCachedResponses()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for _ in 0..<10 {
            let data = try await fetchData(makeRequest(path: "/json/large"))
            bytes += data.count
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 10)
    }

    func tearDown() async throws {}
}

struct PostBatchScenario: TestScenario {
    let scenarioName = "post_batch"
    let libraryName = "Alamofire"
    let libraryVersion = "5.4.0"
    let category = "networking"

    func setUp() async throws {
        URLCache.shared.removeAllCachedResponses()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        let body = makePostBody()
        for _ in 0..<50 {
            let data = try await fetchData(makeRequest(path: "/post", method: .post, body: body))
            bytes += data.count
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 50)
    }

    func tearDown() async throws {}
}

struct ConcurrentGetScenario: TestScenario {
    let scenarioName = "concurrent_get"
    let libraryName = "Alamofire"
    let libraryVersion = "5.4.0"
    let category = "networking"

    func setUp() async throws {
        URLCache.shared.removeAllCachedResponses()
    }

    func run() async throws -> IterationMetrics {
        try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let data = try await fetchData(makeRequest(path: "/json/standard"))
                    return data.count
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

struct ImageDownloadScenario: TestScenario {
    let scenarioName = "image_download"
    let libraryName = "Alamofire"
    let libraryVersion = "5.4.0"
    let category = "networking"

    func setUp() async throws {
        URLCache.shared.removeAllCachedResponses()
    }

    func run() async throws -> IterationMetrics {
        var bytes = 0
        for _ in 0..<10 {
            let data = try await fetchData(makeRequest(path: "/image/medium"))
            bytes += data.count
        }
        return IterationMetrics(bytesTransferred: bytes, itemsProcessed: 10)
    }

    func tearDown() async throws {}
}
