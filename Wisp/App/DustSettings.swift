import Combine
import CoreGraphics
import Foundation

final class DustSettings: ObservableObject {

    // MARK: - Persisted properties

    @Published var theme: ColorTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    @Published var customColor1: CGColor {
        didSet { if let d = customColor1.encoded { UserDefaults.standard.set(d, forKey: "customColor1") } }
    }
    @Published var customColor2: CGColor {
        didSet { if let d = customColor2.encoded { UserDefaults.standard.set(d, forKey: "customColor2") } }
    }
    @Published var customColor3: CGColor {
        didSet { if let d = customColor3.encoded { UserDefaults.standard.set(d, forKey: "customColor3") } }
    }
    @Published var density: Float {
        didSet { UserDefaults.standard.set(density, forKey: "density") }
    }
    @Published var speed: Float {
        didSet { UserDefaults.standard.set(speed, forKey: "speed") }
    }
    @Published var size: Float {
        didSet { UserDefaults.standard.set(size, forKey: "size") }
    }
    @Published var opacity: Float {
        didSet { UserDefaults.standard.set(opacity, forKey: "opacity") }
    }
    @Published var lifespan: Float {
        didSet { UserDefaults.standard.set(lifespan, forKey: "lifespan") }
    }
    @Published var drift: Float {
        didSet { UserDefaults.standard.set(drift, forKey: "drift") }
    }
    @Published var glow: Bool {
        didSet { UserDefaults.standard.set(glow, forKey: "glow") }
    }
    @Published var windX: Float {
        didSet { UserDefaults.standard.set(windX, forKey: "windX") }
    }
    @Published var windY: Float {
        didSet { UserDefaults.standard.set(windY, forKey: "windY") }
    }
    @Published var excludeFromScreenshots: Bool {
        didSet { UserDefaults.standard.set(excludeFromScreenshots, forKey: "excludeFromScreenshots") }
    }
    @Published var pauseOnBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnBattery, forKey: "pauseOnBattery") }
    }

    // MARK: - Init (loads from UserDefaults)

    init() {
        let ud = UserDefaults.standard

        theme = ColorTheme(rawValue: ud.string(forKey: "theme") ?? "") ?? .golden

        customColor1 = ud.data(forKey: "customColor1").flatMap(CGColor.decode) ?? CGColor(red: 1,   green: 1,   blue: 1, alpha: 1)
        customColor2 = ud.data(forKey: "customColor2").flatMap(CGColor.decode) ?? CGColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)
        customColor3 = ud.data(forKey: "customColor3").flatMap(CGColor.decode) ?? CGColor(red: 0.8, green: 0.6, blue: 1, alpha: 1)

        density  = ud.object(forKey: "density")  != nil ? ud.float(forKey: "density")  : 1.0
        speed    = ud.object(forKey: "speed")    != nil ? ud.float(forKey: "speed")    : 1.0
        size     = ud.object(forKey: "size")     != nil ? ud.float(forKey: "size")     : 1.0
        opacity  = ud.object(forKey: "opacity")  != nil ? ud.float(forKey: "opacity")  : 1.0
        lifespan = ud.object(forKey: "lifespan") != nil ? ud.float(forKey: "lifespan") : 1.0
        drift    = ud.object(forKey: "drift")    != nil ? ud.float(forKey: "drift")    : 1.0
        glow     = ud.object(forKey: "glow")     != nil ? ud.bool(forKey:  "glow")     : true
        windX    = ud.object(forKey: "windX")    != nil ? ud.float(forKey: "windX")    : 0
        windY    = ud.object(forKey: "windY")    != nil ? ud.float(forKey: "windY")    : 0

        excludeFromScreenshots = ud.object(forKey: "excludeFromScreenshots") != nil
            ? ud.bool(forKey: "excludeFromScreenshots") : false
        pauseOnBattery = ud.object(forKey: "pauseOnBattery") != nil
            ? ud.bool(forKey: "pauseOnBattery") : false
    }

    // MARK: - Config

    var config: DustConfig {
        return DustConfig(
            theme: theme, customColors: [customColor1, customColor2, customColor3],
            density: density, speed: speed, size: size,
            opacity: opacity, lifespan: lifespan,
            drift: drift, glow: glow, windX: windX, windY: windY,
            excludeFromScreenshots: excludeFromScreenshots
        )
    }
}

// MARK: - CGColor persistence helpers

private extension CGColor {
    var encoded: Data? {
        guard let comps = components, let cs = colorSpace?.name else { return nil }
        let dict: [String: Any] = [
            "components": comps.map { Double($0) },
            "colorSpace": cs as String
        ]
        return try? PropertyListSerialization.data(fromPropertyList: dict,
                                                   format: .binary, options: 0)
    }

    static func decode(from data: Data) -> CGColor? {
        guard let dict = try? PropertyListSerialization.propertyList(from: data,
                                                                      format: nil) as? [String: Any],
              let comps = dict["components"] as? [Double],
              let csName = dict["colorSpace"] as? String,
              let cs = CGColorSpace(name: csName as CFString)
        else { return nil }
        let cgComps = comps.map { CGFloat($0) }
        return CGColor(colorSpace: cs, components: cgComps)
    }
}
