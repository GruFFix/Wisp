import CoreGraphics
import SwiftUI

// MARK: - Color theme catalogue

enum ColorTheme: String, CaseIterable, Identifiable {
    case golden    = "Golden"
    case rose      = "Rose"
    case moonlight = "Moonlight"
    case aurora    = "Aurora"
    case sapphire  = "Sapphire"
    case custom    = "Custom"

    var id: String { rawValue }

    var swatchColors: [Color] {
        switch self {
        case .golden:    return [.yellow, .orange, Color(red: 1, green: 0.9, blue: 0.4)]
        case .rose:      return [.pink, Color(red: 1, green: 0.4, blue: 0.7), .red.opacity(0.6)]
        case .moonlight: return [.white, Color(red: 0.85, green: 0.9, blue: 1), .cyan.opacity(0.5)]
        case .aurora:    return [.green, .teal, .purple]
        case .sapphire:  return [Color(red: 0.3, green: 0.5, blue: 1), .cyan, Color(red: 0.1, green: 0.3, blue: 0.9)]
        case .custom:    return [.white]
        }
    }

    // Returns (main, bright, glow) colours for this theme.
    // Custom and Wallpaper themes return one group per provided colour (up to 3).
    func palette(customColors: [CGColor]) -> [(main: CGColor, bright: CGColor, glow: CGColor)] {
        switch self {
        case .golden:
            return [(.rgb(1.00, 0.82, 0.18), .rgb(1, 1, 0.85), .rgb(1.00, 0.72, 0.10, 0.14))]
        case .rose:
            return [(.rgb(1.00, 0.45, 0.72), .rgb(1.00, 0.80, 0.88), .rgb(0.95, 0.20, 0.55, 0.12))]
        case .moonlight:
            return [(.rgb(0.88, 0.92, 1.00), .rgb(1, 1, 1), .rgb(0.70, 0.82, 1.00, 0.11))]
        case .aurora:
            return [
                (.rgb(0.10, 0.95, 0.55), .rgb(0.80, 1.00, 0.90), .rgb(0.00, 0.80, 0.50, 0.11)),
                (.rgb(0.00, 0.82, 0.95), .rgb(0.70, 1.00, 1.00), .rgb(0.00, 0.60, 0.90, 0.09)),
                (.rgb(0.65, 0.15, 0.95), .rgb(0.90, 0.70, 1.00), .rgb(0.50, 0.05, 0.80, 0.09)),
            ]
        case .sapphire:
            return [(.rgb(0.30, 0.55, 1.00), .rgb(0.75, 0.88, 1.00), .rgb(0.15, 0.35, 0.95, 0.12))]
        case .custom:
            return customColors.map { c in
                let (r, g, b) = c.rgbComponents
                return (.rgb(r, g, b),
                        .rgb(min(r+0.3,1), min(g+0.3,1), min(b+0.3,1)),
                        .rgb(r*0.8, g*0.8, b*0.8, 0.12))
            }
        }
    }
}

private extension CGColor {
    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    /// Safe RGB extraction — converts to sRGB first so any color space (grayscale, CMYK, P3…) works.
    var rgbComponents: (r: CGFloat, g: CGFloat, b: CGFloat) {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
        if let converted = self.converted(to: srgb, intent: .defaultIntent, options: nil),
           let comps = converted.components, comps.count >= 3 {
            return (comps[0], comps[1], comps[2])
        }
        // Fallback: treat as opaque white rather than crash
        return (1, 1, 1)
    }
}
