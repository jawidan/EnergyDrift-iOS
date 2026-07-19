import Foundation

final class ResultsLogger {
    struct Row {
        let scenarioName: String
        let library: String
        let version: String
        let iteration: Int
        let durationMs: Double
        let cpuTimeMs: Double
        let bytesTransferred: Int
        let itemsProcessed: Int
        let deviceModel: String
        let osVersion: String
        let batteryLevelPct: Double
        let thermalState: String
        let timestampISO8601: String
    }

    private static let header = "scenario_name,library,version,iteration,duration_ms,cpu_time_ms,bytes_transferred,items_processed,device_model,os_version,battery_level_pct,thermal_state,timestamp_iso8601"

    private(set) var fileName: String
    private var lines: [String]
    private let fileURL: URL

    init(library: String, version: String, date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let stamp = formatter.string(from: date)
        let fileName = "energydrift_\(library)_\(version)_\(stamp).csv"
        self.fileName = fileName
        self.lines = [Self.header]

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsURL.appendingPathComponent(fileName)
    }

    func append(_ row: Row) {
        let fields: [String] = [
            row.scenarioName,
            row.library,
            row.version,
            String(row.iteration),
            String(format: "%.3f", row.durationMs),
            String(format: "%.3f", row.cpuTimeMs),
            String(row.bytesTransferred),
            String(row.itemsProcessed),
            row.deviceModel,
            row.osVersion,
            String(format: "%.1f", row.batteryLevelPct),
            row.thermalState,
            row.timestampISO8601,
        ]
        lines.append(fields.map(Self.csvEscape).joined(separator: ","))
    }

    func flush() throws {
        let content = lines.joined(separator: "\n") + "\n"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func csvEscape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
