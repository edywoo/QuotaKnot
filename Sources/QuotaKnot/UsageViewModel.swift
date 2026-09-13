import AppKit
import Foundation
import QuotaKnotCore

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var now = Date()
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var lastRefreshReason: RefreshReason?
    @Published private(set) var presentedError: PresentedError?
    @Published private(set) var isRefreshing = false
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
        }
    }

    private let client = CodexUsageClient()
    private var countdownTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var activityMonitor: CodexSessionActivityMonitor?
    private var pendingRefreshReason: RefreshReason?
    private let cacheKey = "lastUsageSnapshot"
    private static let languageKey = "appLanguage"

    init() {
        if let storedLanguage = UserDefaults.standard.string(forKey: Self.languageKey),
           let language = AppLanguage(rawValue: storedLanguage) {
            self.language = language
        } else {
            language = .preferred()
        }

        loadCachedSnapshot()
        countdownTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                self?.now = Date()
            }
        }
        refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await self?.refresh(reason: .scheduled)
            }
        }
        activityMonitor = CodexSessionActivityMonitor { [weak self] activity in
            let reason: RefreshReason = switch activity {
            case .questionSent: .questionSent
            case .responseCompleted: .responseCompleted
            }
            Task { @MainActor [weak self] in
                await self?.refresh(reason: reason)
            }
        }
        activityMonitor?.start()
        Task {
            await refresh(reason: .appLaunch)
        }
    }

    deinit {
        countdownTask?.cancel()
        refreshTask?.cancel()
        activityMonitor?.stop()
    }

    var copy: LocalizedCopy {
        LocalizedCopy(language: language)
    }

    var menuBarText: String {
        guard let snapshot else {
            return isRefreshing ? copy.refreshing : copy.waitingForUsage
        }

        return "\(copy.fiveHourLimit) \(percentText(snapshot.fiveHourRemainingPercent)) (\(resetTime(for: snapshot.fiveHourResetsAt))) · \(copy.weeklyLimit) \(percentText(snapshot.weeklyRemainingPercent)) (\(resetTime(for: snapshot.weeklyResetsAt)))"
    }

    var fiveHourPercent: Int? {
        snapshot?.fiveHourRemainingPercent
    }

    var weeklyPercent: Int? {
        snapshot?.weeklyRemainingPercent
    }

    var fiveHourStatusText: String {
        limitStatus(percent: fiveHourPercent, resetDate: snapshot?.fiveHourResetsAt)
    }

    var weeklyStatusText: String {
        limitStatus(percent: weeklyPercent, resetDate: snapshot?.weeklyResetsAt)
    }

    var lastUpdatedText: String {
        guard let lastUpdatedAt else { return copy.notUpdatedYet }
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let reason = lastRefreshReason.map { " · \(copy.reason($0))" } ?? ""
        return "\(copy.lastUpdated): \(formatter.string(from: lastUpdatedAt))\(reason)"
    }

    var errorMessage: String? {
        presentedError.map { copy.errorMessage(for: $0) }
    }

    func progress(for percent: Int?) -> Double {
        Double(min(100, max(0, percent ?? 0))) / 100
    }

    func refresh(reason: RefreshReason = .manual) async {
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
                presentedError = nil
                save(snapshot: newSnapshot)
            } catch {
                presentedError = presentationError(from: error)
            }

            guard let nextReason = pendingRefreshReason else { break }
            pendingRefreshReason = nil
            currentReason = nextReason
        }
        isRefreshing = false
    }

    func openCodex() {
        guard let url = CodexInstallationLocator.desktopAppURL() else {
            presentedError = .desktopAppNotFound
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func limitStatus(percent: Int?, resetDate: Date?) -> String {
        guard snapshot != nil else { return copy.waitingForUsage }
        let reset = resetDate.map { copy.resetsIn(localizedRemainingTime(until: $0)) }
            ?? copy.resetUnavailable
        return "\(percentText(percent)) · \(reset)"
    }

    private func resetTime(for resetDate: Date?) -> String {
        resetDate.map { localizedRemainingTime(until: $0) } ?? copy.unavailable
    }

    private func localizedRemainingTime(until resetDate: Date) -> String {
        RemainingTimeFormatter.string(until: resetDate, now: now, language: language)
    }

    private func presentationError(from error: Error) -> PresentedError {
        guard let usageError = error as? CodexUsageError else {
            return .unexpected(error.localizedDescription)
        }

        return switch usageError {
        case .executableNotFound: .executableNotFound
        case .processFailed(let detail): .processFailed(detail)
        case .serverError(let detail): .serverError(detail)
        case .missingRateLimits: .missingRateLimits
        case .timedOut: .timedOut
        }
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
