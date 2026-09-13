import Foundation

public enum CodexUsageError: LocalizedError {
    case executableNotFound
    case processFailed(String)
    case serverError(String)
    case missingRateLimits

    public var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "코덱스 실행 파일을 찾지 못했습니다. Codex 데스크톱 앱 또는 CLI가 설치되어 있는지 확인해 주세요."
        case .processFailed(let message):
            return "코덱스 사용량을 읽지 못했습니다: \(message)"
        case .serverError(let message):
            return "코덱스가 오류를 반환했습니다: \(message)"
        case .missingRateLimits:
            return "응답에 5시간/주간 한도 정보가 없습니다. 코덱스에 로그인되어 있는지 확인해 주세요."
        }
    }
}

public struct CodexUsageClient: Sendable {
    public init() {}

    public func fetch() async throws -> UsageSnapshot {
        try await Task.detached(priority: .utility) {
            try fetchSynchronously()
        }.value
    }
}

private func fetchSynchronously() throws -> UsageSnapshot {
    guard let executableURL = CodexInstallationLocator.executableURL() else {
        throw CodexUsageError.executableNotFound
    }

    let process = Process()
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let watchdog = DispatchWorkItem {
        if process.isRunning {
            process.terminate()
        }
    }

    process.executableURL = executableURL
    process.arguments = ["app-server", "--stdio"]
    process.standardInput = inputPipe
    process.standardOutput = outputPipe
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
    } catch {
        throw CodexUsageError.processFailed(error.localizedDescription)
    }

    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 15, execute: watchdog)
    defer {
        watchdog.cancel()
        try? inputPipe.fileHandleForWriting.close()
        try? outputPipe.fileHandleForReading.close()
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
    }

    let clientVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        ?? "development"
    let requests = [
        #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"quotaknot","version":"\#(clientVersion)"},"capabilities":{"experimentalApi":true}}}"#,
        #"{"method":"initialized"}"#,
        #"{"id":2,"method":"account/rateLimits/read"}"#
    ].joined(separator: "\n") + "\n"

    do {
        try inputPipe.fileHandleForWriting.write(contentsOf: Data(requests.utf8))
    } catch {
        throw CodexUsageError.processFailed(error.localizedDescription)
    }

    var buffer = Data()
    while true {
        let chunk = outputPipe.fileHandleForReading.availableData
        if chunk.isEmpty {
            break
        }
        buffer.append(chunk)

        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            let line = buffer[..<newlineIndex]
            buffer.removeSubrange(...newlineIndex)

            guard !line.isEmpty,
                  let envelope = try? JSONDecoder().decode(RPCEnvelope.self, from: Data(line)),
                  envelope.id == 2 else {
                continue
            }

            if let error = envelope.error {
                throw CodexUsageError.serverError(error.message)
            }
            guard let limits = envelope.result?.codexLimits,
                  limits.primary != nil || limits.secondary != nil else {
                throw CodexUsageError.missingRateLimits
            }

            let primary = limits.primary
            let secondary = limits.secondary

            return UsageSnapshot(
                fiveHourRemainingPercent: primary.map { remainingPercent(fromUsedPercent: $0.usedPercent) },
                weeklyRemainingPercent: secondary.map { remainingPercent(fromUsedPercent: $0.usedPercent) },
                fiveHourResetsAt: primary?.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                weeklyResetsAt: secondary?.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            )
        }
    }

    throw CodexUsageError.processFailed("15초 안에 응답을 받지 못했습니다.")
}

private func remainingPercent(fromUsedPercent usedPercent: Int) -> Int {
    min(100, max(0, 100 - usedPercent))
}
