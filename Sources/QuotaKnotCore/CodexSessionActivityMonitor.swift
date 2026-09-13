import CoreServices
import Foundation

public enum CodexSessionActivity: String, Equatable, Sendable {
    case questionSent
    case responseCompleted
}

public enum CodexSessionActivityDetector {
    private static let eventEnvelope = Data(#""type":"event_msg","payload":{"type":""#.utf8)
    private static let questionSent = Data(#""payload":{"type":"task_started""#.utf8)
    private static let responseCompleted = Data(#""payload":{"type":"task_complete""#.utf8)

    public static func activities(in data: Data) -> [CodexSessionActivity] {
        data.split(separator: 0x0A).compactMap { line in
            let lineData = Data(line)
            guard lineData.range(of: eventEnvelope) != nil else {
                return nil
            }

            if lineData.range(of: questionSent) != nil {
                return .questionSent
            }
            if lineData.range(of: responseCompleted) != nil {
                return .responseCompleted
            }
            return nil
        }
    }
}

public final class CodexSessionActivityMonitor {
    public typealias ActivityHandler = (CodexSessionActivity) -> Void

    private let sessionsURL: URL
    private let activityHandler: ActivityHandler
    private let queue = DispatchQueue(label: "com.quotaknot.session-events")
    private var stream: FSEventStreamRef?
    private var offsets: [String: UInt64] = [:]
    private var partialLines: [String: Data] = [:]

    public convenience init(activityHandler: @escaping ActivityHandler) {
        let sessionsURL = CodexInstallationLocator.codexHomeURL()
            .appendingPathComponent("sessions", isDirectory: true)
        self.init(sessionsURL: sessionsURL, activityHandler: activityHandler)
    }

    public init(sessionsURL: URL, activityHandler: @escaping ActivityHandler) {
        self.sessionsURL = sessionsURL
        self.activityHandler = activityHandler
    }

    public func start() {
        queue.sync {
            guard stream == nil,
                  FileManager.default.fileExists(atPath: sessionsURL.path) else {
                return
            }

            seedOffsetsForRecentlyChangedFiles()

            var context = FSEventStreamContext(
                version: 0,
                info: Unmanaged.passUnretained(self).toOpaque(),
                retain: nil,
                release: nil,
                copyDescription: nil
            )
            let flags = FSEventStreamCreateFlags(
                kFSEventStreamCreateFlagUseCFTypes
                    | kFSEventStreamCreateFlagFileEvents
                    | kFSEventStreamCreateFlagNoDefer
            )

            guard let newStream = FSEventStreamCreate(
                kCFAllocatorDefault,
                sessionEventCallback,
                &context,
                [sessionsURL.path] as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                0.25,
                flags
            ) else {
                return
            }

            FSEventStreamSetDispatchQueue(newStream, queue)
            guard FSEventStreamStart(newStream) else {
                FSEventStreamInvalidate(newStream)
                FSEventStreamRelease(newStream)
                return
            }
            stream = newStream
        }
    }

    public func stop() {
        queue.sync {
            guard let stream else { return }
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    fileprivate func handleChangedPaths(_ paths: [String]) {
        for path in paths where path.hasSuffix(".jsonl") {
            for activity in consumeNewActivities(atPath: path) {
                activityHandler(activity)
            }
        }
    }

    private func seedOffsetsForRecentlyChangedFiles() {
        let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: sessionsURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return
        }

        let recentCutoff = Date().addingTimeInterval(-2 * 86_400)
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "jsonl" {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true,
                  let modifiedAt = values.contentModificationDate,
                  modifiedAt >= recentCutoff,
                  let fileSize = values.fileSize else {
                continue
            }
            offsets[fileURL.path] = UInt64(fileSize)
        }
    }

    private func consumeNewActivities(atPath path: String) -> [CodexSessionActivity] {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let sizeNumber = attributes[.size] as? NSNumber else {
            return []
        }

        let currentSize = sizeNumber.uint64Value
        var previousOffset = offsets[path] ?? 0
        if currentSize < previousOffset {
            previousOffset = 0
            partialLines[path] = nil
        }
        guard currentSize > previousOffset,
              let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) else {
            return []
        }
        defer { try? handle.close() }

        do {
            try handle.seek(toOffset: previousOffset)
            let appended = try handle.readToEnd() ?? Data()
            offsets[path] = currentSize

            var completeData = partialLines[path] ?? Data()
            completeData.append(appended)

            guard let lastNewline = completeData.lastIndex(of: 0x0A) else {
                partialLines[path] = completeData
                return []
            }

            let parseable = completeData[...lastNewline]
            let remainderStart = completeData.index(after: lastNewline)
            partialLines[path] = Data(completeData[remainderStart...])
            return CodexSessionActivityDetector.activities(in: Data(parseable))
        } catch {
            return []
        }
    }
}

private let sessionEventCallback: FSEventStreamCallback = {
    _, clientInfo, _, eventPaths, _, _ in
    guard let clientInfo else { return }
    let monitor = Unmanaged<CodexSessionActivityMonitor>
        .fromOpaque(clientInfo)
        .takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
    monitor.handleChangedPaths(paths)
}
