import SwiftUI

@main
struct ClaudeUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let monitor = UsageMonitor()
    private var heatmapView: HeatmapStatusView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        heatmapView = HeatmapStatusView(frame: NSRect(x: 0, y: 0, width: 48, height: 22))
        statusItem.button?.addSubview(heatmapView)
        statusItem.button?.frame.size.width = 48
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 280)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView(monitor: monitor)
        )

        monitor.onUpdate = { [weak self] in
            self?.updateHeatmap()
        }
        monitor.startMonitoring()
    }

    private func updateHeatmap() {
        let session = monitor.usage?.fiveHour?.utilization ?? 0
        let weekly = monitor.usage?.sevenDay?.utilization ?? 0
        heatmapView.update(sessionPercent: session, weeklyPercent: weekly)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
