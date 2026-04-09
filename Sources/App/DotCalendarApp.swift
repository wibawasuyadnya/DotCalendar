import SwiftUI

@main
struct DotCalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showInMenuBar") private var showInMenuBar = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showInMenuBar) {
            CalendarDisplayView()
                .environmentObject(WallpaperEngine.shared)
        } label: {
            Image(systemName: "circle.grid.3x3.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(WallpaperEngine.shared)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance: if already running, tell existing instance to show settings and quit
        let dominated = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        if dominated.count > 1 {
            // Notify existing instance to show settings
            DistributedNotificationCenter.default().postNotificationName(
                .init("\(Bundle.main.bundleIdentifier!).showSettings"),
                object: nil
            )
            // Quit this duplicate
            DispatchQueue.main.async { NSApp.terminate(nil) }
            return
        }

        // Listen for show-settings requests from duplicate launches
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleShowSettings),
            name: .init("\(Bundle.main.bundleIdentifier!).showSettings"),
            object: nil
        )

        Task { @MainActor in
            WallpaperEngine.shared.generateAndApply()
            WallpaperEngine.shared.setupWakeNotification()
        }

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleShowSettings() {
        DispatchQueue.main.async { [weak self] in
            self?.showSettingsWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }

    @objc private func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        if let existing = settingsWindow {
            existing.level = .floating
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsView()
                .environmentObject(WallpaperEngine.shared)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DotCalendar Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
