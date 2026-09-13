import AppKit
import QuotaKnotCore
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var now = Date()
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var lastRefreshReason: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefreshing = false

    private let client = CodexUsageClient()
    private var countdownTimer: Timer?
    private var refreshTimer: Timer?
    private var activityMonitor: CodexSessionActivityMonitor?
    private var pendingRefreshReason: String?
    private let cacheKey = "lastUsageSnapshot"

    init() {
        loadCachedSnapshot()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh(reason: "1분 주기")
            }
        }
        activityMonitor = CodexSessionActivityMonitor { [weak self] activity in
            let reason = switch activity {
            case .questionSent: "질문 전송"
            case .responseCompleted: "응답 완료"
            }
            Task { @MainActor in
                await self?.refresh(reason: reason)
            }
        }
        activityMonitor?.start()
        Task {
            await refresh(reason: "앱 시작")
        }
    }

    deinit {
        countdownTimer?.invalidate()
        refreshTimer?.invalidate()
        activityMonitor?.stop()
    }

    var menuBarText: String {
        guard let snapshot else {
            return isRefreshing ? "코덱스 한도 불러오는 중…" : "코덱스 한도 확인 필요"
        }

        let weeklyRemaining = snapshot.weeklyResetsAt.map {
            RemainingTimeFormatter.string(until: $0, now: now)
        } ?? "확인 불가"
        let fiveHourRemaining = snapshot.fiveHourResetsAt.map {
            RemainingTimeFormatter.string(until: $0, now: now)
        } ?? "초기화 확인 중"
        return "5시간 \(percentText(snapshot.fiveHourRemainingPercent)) (\(fiveHourRemaining)) · 주간 \(percentText(snapshot.weeklyRemainingPercent)) (\(weeklyRemaining))"
    }

    var fiveHourDetail: String {
        guard let snapshot else { return "확인할 수 없음" }
        let percent = percentText(snapshot.fiveHourRemainingPercent)
        guard let resetDate = snapshot.fiveHourResetsAt else {
            return "\(percent) 남음 · 초기화 시각 확인 불가"
        }
        return "\(percent) 남음 · \(RemainingTimeFormatter.string(until: resetDate, now: now)) 뒤 초기화"
    }

    var weeklyDetail: String {
        guard let snapshot else { return "확인할 수 없음" }
        let percent = percentText(snapshot.weeklyRemainingPercent)
        guard let resetDate = snapshot.weeklyResetsAt else {
            return "\(percent) 남음 · 초기화 시각 확인 불가"
        }
        return "\(percent) 남음 · \(RemainingTimeFormatter.string(until: resetDate, now: now)) 뒤 초기화"
    }

    var lastUpdatedText: String {
        guard let lastUpdatedAt else { return "아직 업데이트되지 않음" }
        let reason = lastRefreshReason.map { " · \($0)" } ?? ""
        return "마지막 업데이트: \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))\(reason)"
    }

    func refresh(reason: String = "수동") async {
        if isRefreshing {
            pendingRefreshReason = reason
            return
        }
        isRefreshing = true
        var currentReason = reason

        while true {
            do {
                let newSnapshot = try await client.fetch()
                snapshot = newSnapshot
                now = Date()
                lastUpdatedAt = now
                lastRefreshReason = currentReason
                errorMessage = nil
                save(snapshot: newSnapshot)
            } catch {
                errorMessage = error.localizedDescription
            }

            guard let nextReason = pendingRefreshReason else { break }
            pendingRefreshReason = nil
            currentReason = nextReason
        }
        isRefreshing = false
    }

    func openCodex() {
        guard let url = CodexInstallationLocator.desktopAppURL() else {
            errorMessage = "Codex 또는 ChatGPT 데스크톱 앱을 찾지 못했습니다."
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func save(snapshot: UsageSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func loadCachedSnapshot() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return
        }
        snapshot = cached
    }

    private func percentText(_ percent: Int?) -> String {
        percent.map { "\($0)%" } ?? "—"
    }
}
