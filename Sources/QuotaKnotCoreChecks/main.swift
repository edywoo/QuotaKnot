import QuotaKnotCore
import Darwin
import Foundation

let now = Date(timeIntervalSince1970: 1_000_000)
let checks: [(name: String, reset: Date, expected: String)] = [
    (
        "24시간 미만",
        now.addingTimeInterval(6 * 3_600 + 23 * 60),
        "6시간 23분"
    ),
    (
        "24시간 이상",
        now.addingTimeInterval(29 * 3_600 + 59 * 60),
        "1일 5시간"
    ),
    (
        "여러 날",
        now.addingTimeInterval(6 * 86_400 + 4 * 3_600),
        "6일 4시간"
    ),
    (
        "지난 초기화 시각",
        now.addingTimeInterval(-1),
        "초기화 확인 중"
    )
]

for check in checks {
    let actual = RemainingTimeFormatter.string(until: check.reset, now: now)
    guard actual == check.expected else {
        FileHandle.standardError.write(
            Data("실패: \(check.name) — 예상 '\(check.expected)', 실제 '\(actual)'\n".utf8)
        )
        exit(EXIT_FAILURE)
    }
}

print("남은 시간 형식 검증 \(checks.count)개 통과")

let activityData = Data(
    """
    {"type":"event_msg","payload":{"type":"task_started"}}
    {"type":"response_item","payload":{"type":"message","role":"assistant"}}
    {"type":"event_msg","payload":{"type":"task_complete"}}

    """.utf8
)
let activities = CodexSessionActivityDetector.activities(in: activityData)
guard activities == [.questionSent, .responseCompleted] else {
    FileHandle.standardError.write(Data("실패: 질문/응답 이벤트 감지\n".utf8))
    exit(EXIT_FAILURE)
}

print("질문/응답 이벤트 감지 2개 통과")

let temporarySessions = FileManager.default.temporaryDirectory
    .appendingPathComponent("codex-usage-monitor-\(UUID().uuidString)", isDirectory: true)
try FileManager.default.createDirectory(at: temporarySessions, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temporarySessions) }

let eventSemaphore = DispatchSemaphore(value: 0)
let receivedLock = NSLock()
var receivedActivities: [CodexSessionActivity] = []
let monitor = CodexSessionActivityMonitor(sessionsURL: temporarySessions) { activity in
    receivedLock.lock()
    receivedActivities.append(activity)
    receivedLock.unlock()
    eventSemaphore.signal()
}
monitor.start()

let liveSession = temporarySessions.appendingPathComponent("live-session.jsonl")
try Data("{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_started\"}}\n".utf8)
    .write(to: liveSession)
guard eventSemaphore.wait(timeout: .now() + 3) == .success else {
    FileHandle.standardError.write(Data("실패: 질문 파일 이벤트 수신 시간 초과\n".utf8))
    exit(EXIT_FAILURE)
}

let liveHandle = try FileHandle(forWritingTo: liveSession)
try liveHandle.seekToEnd()
try liveHandle.write(contentsOf: Data("{\"type\":\"event_msg\",\"payload\":{\"type\":\"task_complete\"}}\n".utf8))
try liveHandle.close()
guard eventSemaphore.wait(timeout: .now() + 3) == .success else {
    FileHandle.standardError.write(Data("실패: 응답 완료 파일 이벤트 수신 시간 초과\n".utf8))
    exit(EXIT_FAILURE)
}
monitor.stop()

receivedLock.lock()
let liveActivities = receivedActivities
receivedLock.unlock()
guard liveActivities == [.questionSent, .responseCompleted] else {
    FileHandle.standardError.write(Data("실패: 실제 파일 이벤트 순서\n".utf8))
    exit(EXIT_FAILURE)
}

print("실시간 세션 파일 감시 2개 통과")
