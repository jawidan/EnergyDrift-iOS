import Darwin
import Foundation
import os
import UIKit

final class TestRunner {
    struct Progress {
        let completed: Int
        let total: Int
    }

    private let signpostLog = OSLog(subsystem: "com.energydrift", category: "scenario")

    func run(
        scenario: TestScenario,
        iterations: Int = 30,
        onProgress: ((Progress) -> Void)? = nil
    ) async throws -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let logger = ResultsLogger(library: scenario.libraryName, version: scenario.libraryVersion)
        let deviceModel = Self.deviceModel()
        let osVersion = UIDevice.current.systemVersion
        let isoFormatter = ISO8601DateFormatter()
        let clock = ContinuousClock()

        let sessionSignpostID = OSSignpostID(log: signpostLog)
        os_signpost(.begin, log: signpostLog, name: "session_begin", signpostID: sessionSignpostID)

        for iteration in 1...iterations {
            try await scenario.setUp()

            let signpostID = OSSignpostID(log: signpostLog)
            os_signpost(.begin, log: signpostLog, name: "scenario", signpostID: signpostID, "%{public}s", scenario.scenarioName)

            let cpuBefore = Self.currentThreadUserCPUTimeMs()
            let start = clock.now
            let metrics = try await scenario.run()
            let elapsed = start.duration(to: clock.now)
            let cpuAfter = Self.currentThreadUserCPUTimeMs()

            os_signpost(.end, log: signpostLog, name: "scenario", signpostID: signpostID)

            try await scenario.tearDown()

            logger.append(ResultsLogger.Row(
                scenarioName: scenario.scenarioName,
                library: scenario.libraryName,
                version: scenario.libraryVersion,
                iteration: iteration,
                durationMs: elapsed.milliseconds,
                cpuTimeMs: cpuAfter - cpuBefore,
                bytesTransferred: metrics.bytesTransferred,
                itemsProcessed: metrics.itemsProcessed,
                deviceModel: deviceModel,
                osVersion: osVersion,
                batteryLevelPct: Double(UIDevice.current.batteryLevel) * 100,
                thermalState: Self.thermalStateString(),
                timestampISO8601: isoFormatter.string(from: Date())
            ))
            try logger.flush()

            onProgress?(Progress(completed: iteration, total: iterations))
        }

        os_signpost(.end, log: signpostLog, name: "session_end", signpostID: sessionSignpostID)

        return logger.fileName
    }

    private static func currentThreadUserCPUTimeMs() -> Double {
        let thread = mach_thread_self()
        defer { mach_port_deallocate(mach_task_self_, thread) }

        var info = thread_basic_info()
        var count = mach_msg_type_number_t(THREAD_INFO_MAX)
        let kr = withUnsafeMutablePointer(to: &info) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                thread_info(thread, thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }

        return Double(info.user_time.seconds) * 1000 + Double(info.user_time.microseconds) / 1000
    }

    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    private static func thermalStateString() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}

private extension Duration {
    var milliseconds: Double {
        let components = self.components
        return Double(components.seconds) * 1000 + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}
