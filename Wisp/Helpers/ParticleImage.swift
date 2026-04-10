import CoreGraphics

enum ParticleImage {

    static let glow: CGImage = radial(size: 64, falloff: 1.0)
    static let core: CGImage = radial(size: 32, falloff: 0.4)
    static let blob: CGImage = radial(size: 96, falloff: 1.0)
    /// Tiny sharp dot — 8 px with hard falloff, renders as ~1 pt point at scale 0.13
    static let dot:  CGImage = radial(size: 8,  falloff: 0.25)

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


}
