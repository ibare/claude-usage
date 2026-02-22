import SwiftUI

struct MenuContentView: View {
    let monitor: UsageMonitor

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            mainGaugesSection
            Divider()
            footerSection
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Claude Usage")
                .font(.headline)
            Spacer()
            Button(action: {
                Task { await monitor.fetchUsage() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(monitor.isLoading ? 360 : 0))
                    .animation(
                        monitor.isLoading
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: monitor.isLoading
                    )
            }
            .buttonStyle(.plain)
            .disabled(monitor.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Main Gauges

    private var mainGaugesSection: some View {
        HStack(spacing: 24) {
            if let fiveHour = monitor.usage?.fiveHour {
                CircularGaugeView(
                    utilization: fiveHour.utilization,
                    label: "Session (5h)",
                    resetTime: fiveHour.timeUntilReset
                )
            } else {
                CircularGaugeView(utilization: 0, label: "Session (5h)", resetTime: nil)
            }

            if let sevenDay = monitor.usage?.sevenDay {
                CircularGaugeView(
                    utilization: sevenDay.utilization,
                    label: "Weekly (7d)",
                    resetTime: sevenDay.timeUntilReset
                )
            } else {
                CircularGaugeView(utilization: 0, label: "Weekly (7d)", resetTime: nil)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            if let errorMessage = monitor.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 10))
                Text(errorMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if let timeSince = monitor.timeSinceUpdate {
                Text("Updated \(timeSince)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
