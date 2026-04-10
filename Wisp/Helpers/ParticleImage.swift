import CoreGraphics

enum ParticleImage {

    static let glow:  CGImage = radial(size: 64, falloff: 1.0)
    static let core:  CGImage = radial(size: 32, falloff: 0.4)
    static let blob:  CGImage = radial(size: 96, falloff: 1.0)
    static let star:  CGImage = radial(size: 32, falloff: 0.6)
    static let star6: CGImage = radial(size: 32, falloff: 0.7)
    /// Elongated oval (≈ 2:1) — used for ash flake tumbling effect
    static let flake: CGImage = oval(longAxis: 80, shortAxis: 44, falloff: 0.88)
    /// Tiny sharp dot — 8 px with hard falloff, renders as ~1 pt point at scale 0.13
    static let dot:   CGImage = radial(size: 8,  falloff: 0.25)

    // MARK: - Generators

    // Metal-compatible bitmap format: BGRA premultiplied (byteOrder32Little + premultipliedFirst)
    private static let bitmapInfo = CGBitmapInfo(rawValue:
        CGBitmapInfo.byteOrder32Little.rawValue |
        CGImageAlphaInfo.premultipliedFirst.rawValue
    )

    private static func radial(size: Int, falloff: CGFloat) -> CGImage {
        let sz    = CGFloat(size)
        let space = CGColorSpaceCreateDeviceRGB()
        let ctx   = CGContext(data: nil, width: size, height: size,
                              bitsPerComponent: 8, bytesPerRow: 0, space: space,
                              bitmapInfo: bitmapInfo.rawValue)!
        let c      = CGPoint(x: sz / 2, y: sz / 2)
        let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: 1),
                      CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray
        let locs: [CGFloat] = [0, falloff]
        let grad  = CGGradient(colorsSpace: space, colors: colors, locations: locs)!
        ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0,
                               endCenter: c, endRadius: sz / 2, options: [])
        return ctx.makeImage()!
    }

    /// Draws a radial gradient inside a scaled context to produce an elliptical
    /// soft blob (longAxis × shortAxis pixels).  Spinning this texture in
    /// CAEmitterCell gives a visible tumbling motion — crucial for ash flakes.
    private static func oval(longAxis: Int, shortAxis: Int, falloff: CGFloat) -> CGImage {
        let w     = CGFloat(longAxis)
        let h     = CGFloat(shortAxis)
        let space = CGColorSpaceCreateDeviceRGB()
        let ctx   = CGContext(data: nil, width: longAxis, height: shortAxis,
                              bitsPerComponent: 8, bytesPerRow: 0, space: space,
                              bitmapInfo: bitmapInfo.rawValue)!
        let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: 1),
                      CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray
        let locs: [CGFloat] = [0, falloff]
        let grad  = CGGradient(colorsSpace: space, colors: colors, locations: locs)!
        // Stretch the coordinate space so a circular gradient fills the rectangle
        ctx.saveGState()
        ctx.translateBy(x: w / 2, y: h / 2)
        ctx.scaleBy(x: w / h, y: 1.0)          // w/h ≈ 1.82 → horizontal stretch
        ctx.drawRadialGradient(grad, startCenter: .zero, startRadius: 0,
                               endCenter: .zero, endRadius: h / 2,
                               options: [.drawsAfterEndLocation])
        ctx.restoreGState()
        return ctx.makeImage()!
    }

}
