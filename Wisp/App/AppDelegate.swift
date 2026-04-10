import AppKit
import Combine
import SwiftUI
import ServiceManagement
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem:   NSStatusItem!
    private var popover:      NSPopover!
    private var dustWindows:  [DustWindow] = []
    private let settings    = DustSettings()
    private var cancellable: AnyCancellable?

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDustWindows()
        setupMenuBar()
        applyToAll(settings.config)
        setupPerformanceObservers()

        cancellable = settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.applyToAll(self.settings.config)
                }
            }
    }

    // MARK: - Multi-monitor

    private func setupDustWindows() {
        dustWindows.forEach { $0.close() }
        dustWindows = NSScreen.screens.map { screen in
            let w = DustWindow(screen: screen)
            w.orderFront(nil)
            return w
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    @objc private func screensDidChange() {
        let cfg = settings.config
        dustWindows.forEach { $0.close() }
        dustWindows = NSScreen.screens.map { screen in
            let w = DustWindow(screen: screen)
            w.orderFront(nil)
            w.apply(cfg)
            return w
        }
    }

    private func applyToAll(_ cfg: DustConfig) {
        dustWindows.forEach { $0.apply(cfg) }
    }

    // MARK: - Performance: pause on sleep / screen lock

    private func setupPerformanceObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(pause),
                       name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(resume),
                       name: NSWorkspace.screensDidWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(pause),
                       name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        ws.addObserver(self, selector: #selector(resume),
                       name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
    }

    @objc private func pause()  { dustWindows.forEach { $0.pause() } }
    @objc private func resume() { dustWindows.forEach { $0.resume() } }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles",
                                   accessibilityDescription: "Wisp")
            button.action = #selector(togglePopover)
            button.target = self
        }
        buildPopover()
    }

    private func buildPopover() {
        popover = NSPopover()
        popover.behavior   = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(
            rootView: SettingsView(
                settings: settings,
                onClose: { [weak self] in self?.popover.close() },
                onCheckForUpdates: { [weak self] in
                    self?.updaterController.updater.checkForUpdates()
                }
            )
        )
        popover.contentSize = NSSize(width: 300, height: 500)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.close()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
