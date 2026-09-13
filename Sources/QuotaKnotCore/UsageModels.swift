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

public enum RemainingTimeFormatter {
    public static func string(until resetDate: Date, now: Date = Date()) -> String {
        let remainingSeconds = max(0, Int(resetDate.timeIntervalSince(now)))

        if remainingSeconds == 0 {
            return "초기화 확인 중"
        }

        let totalMinutes = remainingSeconds / 60
        if totalMinutes == 0 {
            return "1분 미만"
        }

        let totalHours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if totalHours < 24 {
            return "\(totalHours)시간 \(minutes)분"
        }

        let days = totalHours / 24
        let hours = totalHours % 24
        return "\(days)일 \(hours)시간"
    }
}
