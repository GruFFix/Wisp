import AppKit
import QuartzCore

final class DustWindow: NSWindow {

    private var dustEmitter: DustEmitter!

    init(screen: NSScreen) {
        let frame = screen.frame
        super.init(contentRect: frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)

        backgroundColor      = .clear
        isOpaque             = false
        hasShadow            = false
        ignoresMouseEvents   = true
        level                = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        collectionBehavior   = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false

        let root = CALayer()
        root.frame           = CGRect(origin: .zero, size: frame.size)
        root.backgroundColor = CGColor.clear

        let host = NSView(frame: CGRect(origin: .zero, size: frame.size))
        host.wantsLayer = true
        host.layer      = root
        contentView     = host

        dustEmitter = DustEmitter(hostLayer: root, screenSize: frame.size)
    }

    func apply(_ cfg: DustConfig) {
        sharingType = cfg.excludeFromScreenshots ? .none : .readOnly
        dustEmitter.apply(cfg)
    }
    func pause()                  { dustEmitter.pause() }
    func resume()                 { dustEmitter.resume() }
}
