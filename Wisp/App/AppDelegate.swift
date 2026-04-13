import AppKit
import Combine
import SwiftUI
import ServiceManagement
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem:        NSStatusItem!
    private var panel:             NSPanel!
    private var dustWindows:       [DustWindow] = []
    private let settings         = DustSettings()
    private var cancellable:       AnyCancellable?
    private var updaterController: SPUStandardUpdaterController!
    private var eventMonitor:      Any?
    private var batteryTimer:      DispatchSourceTimer?
    private var isPausedForBattery = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        setupDustWindows()
        setupMenuBar()
        applyToAll(settings.config)
        setupPerformanceObservers()
        setupBatteryMonitoring()

        cancellable = settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.applyToAll(self.settings.config)
                    self.updateBatteryPause()
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

    // MARK: - Battery monitoring

    private func setupBatteryMonitoring() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 30)
        timer.setEventHandler { [weak self] in self?.updateBatteryPause() }
        timer.resume()
        batteryTimer = timer
    }

    private func isOnBattery() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g", "ps"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = Pipe()
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return output.contains("Battery Power")
    }

    private func updateBatteryPause() {
        guard settings.pauseOnBattery else {
            if isPausedForBattery { resume(); isPausedForBattery = false }
            return
        }
        let onBattery = isOnBattery()
        if onBattery, !isPausedForBattery {
            pause(); isPausedForBattery = true
        } else if !onBattery, isPausedForBattery {
            resume(); isPausedForBattery = false
        }
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = menuBarIcon()
            button.action = #selector(togglePanel)
            button.target = self
        }
        buildPanel()
    }

    private func menuBarIcon() -> NSImage? {
        guard let icon = NSImage(named: "AppIcon") else {
            return NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Wisp")
        }
        let size = NSSize(width: 18, height: 18)
        let scaled = NSImage(size: size)
        scaled.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: icon.size),
                  operation: .sourceOver, fraction: 1.0)
        scaled.unlockFocus()
        scaled.isTemplate = false
        return scaled
    }

    private func buildPanel() {
        let hosting = NSHostingController(
            rootView: SettingsView(
                settings: settings,
                onClose: { [weak self] in self?.closePanel() },
                onCheckForUpdates: { [weak self] in
                    self?.updaterController.updater.checkForUpdates()
                }
            )
        )

        hosting.preferredContentSize = NSSize(width: 300, height: 500)

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 500),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: true
        )
        panel.contentViewController = hosting
        panel.setContentSize(NSSize(width: 300, height: 500))
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .auxiliary]
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        guard let button = statusItem.button else { return }
        positionPanel(relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        panel.close()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func positionPanel(relativeTo button: NSButton) {
        guard let buttonWindow = button.window else { return }
        let rectInWindow = button.convert(button.bounds, to: nil)
        let rectOnScreen = buttonWindow.convertToScreen(rectInWindow)

        let panelW: CGFloat = 300
        let gap:    CGFloat = 6

        var x = rectOnScreen.midX - panelW / 2

        if let screen = button.window?.screen ?? NSScreen.main {
            let visibleMinX = screen.visibleFrame.minX + 8
            let visibleMaxX = screen.visibleFrame.maxX - panelW - 8
            x = max(visibleMinX, min(x, visibleMaxX))
        }

        // setFrameTopLeftPoint anchors the top-left corner regardless of panel height
        panel.setFrameTopLeftPoint(NSPoint(x: x, y: rectOnScreen.minY - gap))
    }
}
