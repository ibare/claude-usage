import Foundation
import SwiftUI

@Observable
@MainActor
final class UsageMonitor {
    var usage: UsageResponse?
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?
    var onUpdate: (() -> Void)?

    private let apiService = UsageAPIService()
    private var timer: Timer?
    private static let refreshInterval: TimeInterval = 60 // 1 minute

    var timeSinceUpdate: String? {
        guard let lastUpdated else { return nil }
        let interval = Date().timeIntervalSince(lastUpdated)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }

    var maxUtilization: Double {
        let values = [
            usage?.fiveHour?.utilization,
            usage?.sevenDay?.utilization,
        ].compactMap { $0 }
        return values.max() ?? 0
    }

    func startMonitoring() {
        Task {
            await fetchUsage()
        }
        timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchUsage()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func fetchUsage() async {
        isLoading = true
        errorMessage = nil

        do {
            usage = try await apiService.fetchUsage()
            lastUpdated = Date()
            onUpdate?()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
