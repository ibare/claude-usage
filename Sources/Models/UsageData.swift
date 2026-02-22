import Foundation

// MARK: - API Response

struct UsageResponse: Codable, Sendable {
    let fiveHour: UsagePeriod?
    let sevenDay: UsagePeriod?
    let sevenDaySonnet: UsagePeriod?
    let sevenDayOpus: UsagePeriod?
    let extraUsage: ExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
        case extraUsage = "extra_usage"
    }
}

struct UsagePeriod: Codable, Sendable {
    let utilization: Double
    let resetsAt: Date?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var color: UsageColor {
        switch utilization {
        case ..<50: return .green
        case ..<80: return .yellow
        default: return .red
        }
    }

    var timeUntilReset: String? {
        guard let resetsAt else { return nil }
        let interval = resetsAt.timeIntervalSinceNow
        guard interval > 0 else { return "resetting..." }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours >= 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return "\(days)d \(remainingHours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

enum UsageColor: Sendable {
    case green, yellow, red
}

struct ExtraUsage: Codable, Sendable {
    let isEnabled: Bool
    let monthlyLimit: Int?
    let usedCredits: Double?
    let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}

// MARK: - Keychain Credential

struct KeychainData: Codable, Sendable {
    let claudeAiOauth: ClaudeCredential?
}

struct ClaudeCredential: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Double?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date().timeIntervalSince1970 * 1000 >= expiresAt
    }
}

// MARK: - Token Refresh

struct TokenRefreshRequest: Codable, Sendable {
    let grantType: String
    let refreshToken: String
    let clientId: String
    let scope: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case clientId = "client_id"
        case scope
    }
}

struct TokenRefreshResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
