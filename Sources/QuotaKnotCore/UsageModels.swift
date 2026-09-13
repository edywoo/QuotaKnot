import Foundation

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public let fiveHourRemainingPercent: Int?
    public let weeklyRemainingPercent: Int?
    public let fiveHourResetsAt: Date?
    public let weeklyResetsAt: Date?

    public init(
        fiveHourRemainingPercent: Int?,
        weeklyRemainingPercent: Int?,
        fiveHourResetsAt: Date?,
        weeklyResetsAt: Date?
    ) {
        self.fiveHourRemainingPercent = fiveHourRemainingPercent
        self.weeklyRemainingPercent = weeklyRemainingPercent
        self.fiveHourResetsAt = fiveHourResetsAt
        self.weeklyResetsAt = weeklyResetsAt
    }
}

struct RPCEnvelope: Decodable {
    let id: Int?
    let result: RateLimitsResult?
    let error: RPCError?
}

struct RPCError: Decodable {
    let code: Int?
    let message: String
}

struct RateLimitsResult: Decodable {
    let rateLimits: RateLimitSnapshot?
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?

    var codexLimits: RateLimitSnapshot? {
        rateLimitsByLimitId?["codex"] ?? rateLimits
    }
}

struct RateLimitSnapshot: Decodable {
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
}

struct RateLimitWindow: Decodable {
    let usedPercent: Int
    let windowDurationMins: Int?
    let resetsAt: Int64?

    private enum CodingKeys: String, CodingKey {
        case usedPercent
        case windowDurationMins
        case resetsAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let integer = try? container.decode(Int.self, forKey: .usedPercent) {
            usedPercent = integer
        } else {
            usedPercent = Int(try container.decode(Double.self, forKey: .usedPercent).rounded())
        }
        windowDurationMins = try container.decodeIfPresent(Int.self, forKey: .windowDurationMins)
        resetsAt = try container.decodeIfPresent(Int64.self, forKey: .resetsAt)
    }
}

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case korean = "ko"
    case japanese = "ja"
    case simplifiedChinese = "zh-Hans"

    public static func preferred(from preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard let identifier = preferredLanguages.first?.lowercased() else {
            return .english
        }
        if identifier.hasPrefix("ko") { return .korean }
        if identifier.hasPrefix("ja") { return .japanese }
        if identifier.hasPrefix("zh") { return .simplifiedChinese }
        return .english
    }

    public var nativeName: String {
        switch self {
        case .english: "English"
        case .korean: "한국어"
        case .japanese: "日本語"
        case .simplifiedChinese: "简体中文"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}

public enum RemainingTimeFormatter {
    public static func string(
        until resetDate: Date,
        now: Date = Date(),
        language: AppLanguage = .preferred()
    ) -> String {
        let remainingSeconds = max(0, Int(resetDate.timeIntervalSince(now)))

        if remainingSeconds == 0 {
            return resetPending(language)
        }

        let totalMinutes = remainingSeconds / 60
        if totalMinutes == 0 {
            return lessThanOneMinute(language)
        }

        let totalHours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if totalHours < 24 {
            return hoursAndMinutes(totalHours, minutes, language: language)
        }

        let days = totalHours / 24
        let hours = totalHours % 24
        return daysAndHours(days, hours, language: language)
    }

    private static func resetPending(_ language: AppLanguage) -> String {
        switch language {
        case .english: "checking reset"
        case .korean: "초기화 확인 중"
        case .japanese: "リセット確認中"
        case .simplifiedChinese: "正在确认重置时间"
        }
    }

    private static func lessThanOneMinute(_ language: AppLanguage) -> String {
        switch language {
        case .english: "less than 1m"
        case .korean: "1분 미만"
        case .japanese: "1分未満"
        case .simplifiedChinese: "不到1分钟"
        }
    }

    private static func hoursAndMinutes(_ hours: Int, _ minutes: Int, language: AppLanguage) -> String {
        switch language {
        case .english: "\(hours)h \(minutes)m"
        case .korean: "\(hours)시간 \(minutes)분"
        case .japanese: "\(hours)時間 \(minutes)分"
        case .simplifiedChinese: "\(hours)小时\(minutes)分钟"
        }
    }

    private static func daysAndHours(_ days: Int, _ hours: Int, language: AppLanguage) -> String {
        switch language {
        case .english: "\(days)d \(hours)h"
        case .korean: "\(days)일 \(hours)시간"
        case .japanese: "\(days)日 \(hours)時間"
        case .simplifiedChinese: "\(days)天\(hours)小时"
        }
    }
}
