// Durable one-record-per-line crash persistence shared by desktop companions.
// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

public enum CrashReportLog {
    private struct Entry: Codable {
        let recordedAt: Date
        let report: CrashReport
    }

    private static let lock = NSLock()

    /// Appends one complete structured entry and synchronizes it before returning.
    public static func persist(_ report: CrashReport) throws {
        try persist(report, in: logDirectory())
    }

    static func persist(_ report: CrashReport, in directory: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let file = directory.appendingPathComponent("firmware-crashes.jsonl")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        var data = try encoder.encode(Entry(recordedAt: Date(), report: report))
        data.append(0x0A)

        if FileManager.default.fileExists(atPath: file.path) {
            let handle = try FileHandle(forWritingTo: file)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.synchronize()
        } else {
            try data.write(to: file, options: .atomic)
            let handle = try FileHandle(forWritingTo: file)
            defer { try? handle.close() }
            try handle.synchronize()
        }
    }

    /// The platform application-support folder containing the JSON-lines log.
    public static func logDirectory() throws -> URL {
        if let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupport
                .appendingPathComponent("Obbut", isDirectory: true)
                .appendingPathComponent("KeymapCompanion", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".obbut-keymap-companion", isDirectory: true)
    }
}
