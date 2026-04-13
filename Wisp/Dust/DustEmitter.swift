import QuartzCore
import CoreGraphics

// MARK: - Config

struct DustConfig {
    var theme:        ColorTheme = .golden
    var customColors: [CGColor] = [CGColor(red: 1, green: 1, blue: 1, alpha: 1),
                                   CGColor(red: 0.6, green: 0.8, blue: 1,   alpha: 1),
                                   CGColor(red: 0.8, green: 0.6, blue: 1,   alpha: 1)]
    var density:     Float      = 1.0
    var speed:       Float      = 1.0
    var size:        Float      = 1.0
    var opacity:     Float      = 1.0
    var lifespan:    Float      = 1.0
    var drift:       Float      = 1.0
    var glow:        Bool       = true
    /// Joystick position, each –1…1. (0,0) = calm, (1,0) = full right, (0,1) = full up.
    var windX:       Float      = 0
    var windY:       Float      = 0
    var excludeFromScreenshots: Bool = false
}

// MARK: - Base values (all multipliers = 1.0)

private struct CellBase {
    let birthPerFraction: Float
    let lifetime:         CGFloat
    let lifetimeRange:    CGFloat
    let velocity:         CGFloat
    let velocityRange:    CGFloat
    let scale:            CGFloat
    let scaleRange:       CGFloat
    let yAcceleration:    CGFloat
    let xAccelPerDrift:   CGFloat
}

// Lifetimes are short (8–16 s) so wind direction changes are visible quickly.
// xAccelPerDrift is large enough that drift=1 noticeably biases particle paths.
private let auraBase  = CellBase(birthPerFraction:  2, lifetime: 14, lifetimeRange: 4, velocity:  4, velocityRange:  6, scale: 0.200, scaleRange: 0.070, yAcceleration:  0, xAccelPerDrift: 0.8)
private let nearBase  = CellBase(birthPerFraction:  5, lifetime:  8, lifetimeRange: 3, velocity: 12, velocityRange: 22, scale: 0.110, scaleRange: 0.045, yAcceleration: -1, xAccelPerDrift: 3.5)
private let moteBase  = CellBase(birthPerFraction: 14, lifetime: 10, lifetimeRange: 3, velocity:  8, velocityRange: 18, scale: 0.052, scaleRange: 0.022, yAcceleration: -1, xAccelPerDrift: 3.0)
private let sparkBase = CellBase(birthPerFraction: 22, lifetime: 12, lifetimeRange: 4, velocity:  5, velocityRange: 12, scale: 0.036, scaleRange: 0.015, yAcceleration: -2, xAccelPerDrift: 2.5)
private let dotBase   = CellBase(birthPerFraction: 35, lifetime: 16, lifetimeRange: 5, velocity:  3, velocityRange:  9, scale: 0.130, scaleRange: 0.050, yAcceleration: -2, xAccelPerDrift: 2.0)

// MARK: - DustEmitter

final class DustEmitter {
    private let layer:      CAEmitterLayer
    private var screenSize: CGSize

    private var lastTheme:        ColorTheme?
    private var lastCustomComps:  [[CGFloat]] = []
    private var lastGlow:         Bool?
    private var paletteCount:     Int = 0

    init(hostLayer: CALayer, screenSize: CGSize) {
        self.screenSize = screenSize

        layer = CAEmitterLayer()
        layer.emitterShape = .rectangle
        layer.emitterMode  = .surface
        layer.birthRate    = 1.0

        hostLayer.addSublayer(layer)
    }

    func pause()  { layer.birthRate = 0 }
    func resume() { layer.birthRate = 1 }

    func apply(_ cfg: DustConfig) {
        layer.opacity = cfg.opacity

        let needsRebuild = paletteCount == 0
                        || cfg.theme != lastTheme
                        || cfg.glow  != lastGlow
                        || (cfg.theme == .custom && !customColorsEqual(cfg.customColors, vs: lastCustomComps))
        needsRebuild ? rebuild(cfg) : updateKVC(cfg)
    }

    // MARK: - Full rebuild

    private func rebuild(_ cfg: DustConfig) {
        let parent = layer.superlayer
        layer.removeFromSuperlayer()

        layer.emitterPosition = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        layer.emitterSize     = screenSize
        layer.renderMode      = cfg.glow ? .additive : .oldestLast
        layer.emitterCells    = buildCells(cfg)
        layer.birthRate       = 1
        paletteCount          = cfg.theme.palette(customColors: cfg.customColors).count

        parent?.addSublayer(layer)

        lastTheme       = cfg.theme
        lastGlow        = cfg.glow
        lastCustomComps = cfg.customColors.map { $0.components ?? [] }
    }

    // MARK: - KVC update (zero flicker)

    private func updateKVC(_ cfg: DustConfig) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let fraction = Float(1) / Float(paletteCount)
        for i in 0..<paletteCount {
            setCell("aura_\(i)",  base: auraBase,  fraction: fraction, cfg: cfg)
            setCell("near_\(i)",  base: nearBase,  fraction: fraction, cfg: cfg)
            setCell("mote_\(i)",  base: moteBase,  fraction: fraction, cfg: cfg)
            setCell("spark_\(i)", base: sparkBase, fraction: fraction, cfg: cfg)
            setCell("dot_\(i)",   base: dotBase,   fraction: fraction, cfg: cfg)
        }
        CATransaction.commit()
    }

    private func setCell(_ name: String, base: CellBase, fraction: Float, cfg: DustConfig) {
        let p  = "emitterCells.\(name)"
        let s  = CGFloat(cfg.speed); let z = CGFloat(cfg.size); let dr = CGFloat(cfg.drift)
        let ls = CGFloat(cfg.lifespan)
        let wm = base.xAccelPerDrift * dr
        layer.setValue(base.birthPerFraction * cfg.density * fraction, forKeyPath: p + ".birthRate")
        layer.setValue(base.velocity      * s,                         forKeyPath: p + ".velocity")
        layer.setValue(base.velocityRange * s,                         forKeyPath: p + ".velocityRange")
        layer.setValue(base.scale         * z,                         forKeyPath: p + ".scale")
        layer.setValue(base.scaleRange    * z,                         forKeyPath: p + ".scaleRange")
        layer.setValue(base.lifetime      * ls,                        forKeyPath: p + ".lifetime")
        layer.setValue(base.lifetimeRange * ls,                        forKeyPath: p + ".lifetimeRange")
        layer.setValue(base.yAcceleration * s + wm * CGFloat(cfg.windY), forKeyPath: p + ".yAcceleration")
        layer.setValue(wm * CGFloat(cfg.windX),                          forKeyPath: p + ".xAcceleration")
    }

    // MARK: - Cell construction

    private func buildCells(_ cfg: DustConfig) -> [CAEmitterCell] {
        let palette  = cfg.theme.palette(customColors: cfg.customColors)
        let fraction = Float(1) / Float(palette.count)
        return palette.enumerated().flatMap { i, g in
            makeGroup(i: i, cfg: cfg, fraction: fraction, main: g.main, bright: g.bright, glow: g.glow)
        }
    }

    private func makeGroup(i: Int, cfg: DustConfig, fraction: Float,
                           main: CGColor, bright: CGColor, glow: CGColor) -> [CAEmitterCell] {
        let d    = cfg.density * fraction
        let s    = CGFloat(cfg.speed); let z = CGFloat(cfg.size); let dr = CGFloat(cfg.drift)
        let ls   = CGFloat(cfg.lifespan)
        let wx_n = CGFloat(cfg.windX)
        let wy_n = CGFloat(cfg.windY)

        func wx(_ b: CellBase) -> CGFloat { b.xAccelPerDrift * dr * wx_n }
        func wy(_ b: CellBase) -> CGFloat { b.yAcceleration  * s  + b.xAccelPerDrift * dr * wy_n }

        let aura = makeCell(
            name: "aura_\(i)", tex: ParticleImage.blob,
            birth: auraBase.birthPerFraction * d, life: auraBase.lifetime * ls, lifeRange: auraBase.lifetimeRange * ls,
            vel: auraBase.velocity * s, velRange: auraBase.velocityRange * s,
            scale: auraBase.scale * z, scaleRange: auraBase.scaleRange * z, scaleSpeed: 0.008,
            alphaSpeed: -0.030, alphaRange: 0.08, color: glow,
            yAccel: wy(auraBase), xAccel: wx(auraBase), spin: 0, spinRange: 0.06)

        let near = makeCell(
            name: "near_\(i)", tex: ParticleImage.glow,
            birth: nearBase.birthPerFraction * d, life: nearBase.lifetime * ls, lifeRange: nearBase.lifetimeRange * ls,
            vel: nearBase.velocity * s, velRange: nearBase.velocityRange * s,
            scale: nearBase.scale * z, scaleRange: nearBase.scaleRange * z,
            alphaSpeed: -0.085, alphaRange: 0.30,
            color: main.copy(alpha: 0.82) ?? main,
            yAccel: wy(nearBase), xAccel: wx(nearBase), spin: 0, spinRange: 4.0)

        let mote = makeCell(
            name: "mote_\(i)", tex: ParticleImage.glow,
            birth: moteBase.birthPerFraction * d, life: moteBase.lifetime * ls, lifeRange: moteBase.lifetimeRange * ls,
            vel: moteBase.velocity * s, velRange: moteBase.velocityRange * s,
            scale: moteBase.scale * z, scaleRange: moteBase.scaleRange * z,
            alphaSpeed: -0.058, alphaRange: 0.35,
            color: bright.copy(alpha: 0.68) ?? bright,
            yAccel: wy(moteBase), xAccel: wx(moteBase), spin: 0, spinRange: 6.0)

        let spark = makeCell(
            name: "spark_\(i)", tex: ParticleImage.core,
            birth: sparkBase.birthPerFraction * d, life: sparkBase.lifetime * ls, lifeRange: sparkBase.lifetimeRange * ls,
            vel: sparkBase.velocity * s, velRange: sparkBase.velocityRange * s,
            scale: sparkBase.scale * z, scaleRange: sparkBase.scaleRange * z,
            alphaSpeed: -0.042, alphaRange: 0.40,
            color: main.copy(alpha: 0.55) ?? main,
            yAccel: wy(sparkBase), xAccel: wx(sparkBase), spin: 0, spinRange: 8.0)

        let dot = makeCell(
            name: "dot_\(i)", tex: ParticleImage.dot,
            birth: dotBase.birthPerFraction * d, life: dotBase.lifetime * ls, lifeRange: dotBase.lifetimeRange * ls,
            vel: dotBase.velocity * s, velRange: dotBase.velocityRange * s,
            scale: dotBase.scale * z, scaleRange: dotBase.scaleRange * z,
            alphaSpeed: -0.028, alphaRange: 0.45,
            color: bright.copy(alpha: 0.50) ?? bright,
            yAccel: wy(dotBase), xAccel: wx(dotBase))

        return [aura, near, mote, spark, dot]
    }

    // MARK: - Cell factory

    private func makeCell(name: String, tex: CGImage,
                          birth: Float, life: CGFloat, lifeRange: CGFloat = 0,
                          vel: CGFloat, velRange: CGFloat = 0,
                          emission: CGFloat = .pi * 2, longitude: CGFloat = 0,
                          scale: CGFloat, scaleRange: CGFloat = 0, scaleSpeed: CGFloat = 0,
                          alphaSpeed: CGFloat, alphaRange: CGFloat = 0,
                          color: CGColor,
                          yAccel: CGFloat = 0, xAccel: CGFloat = 0,
                          spin: CGFloat = 0, spinRange: CGFloat = 0) -> CAEmitterCell {
        let c               = CAEmitterCell()
        c.name              = name
        c.contents          = tex
        c.birthRate         = birth
        c.lifetime          = Float(life)
        c.lifetimeRange     = Float(lifeRange)
        c.velocity          = vel
        c.velocityRange     = velRange
        c.emissionRange     = emission
        c.emissionLongitude = longitude
        c.scale             = scale
        c.scaleRange        = scaleRange
        c.scaleSpeed        = scaleSpeed
        c.alphaSpeed        = Float(alphaSpeed)
        c.alphaRange        = Float(alphaRange)
        c.color             = color
        c.yAcceleration     = yAccel
        c.xAcceleration     = xAccel
        c.spin              = spin
        c.spinRange         = spinRange
        return c
    }

    // MARK: - Utilities

    private func customColorsEqual(_ colors: [CGColor], vs old: [[CGFloat]]) -> Bool {
        guard colors.count == old.count else { return false }
        return zip(colors, old).allSatisfy { color, comps in
            guard let c = color.components else { return comps.isEmpty }
            guard c.count == comps.count   else { return false }
            return zip(c, comps).allSatisfy { abs($0 - $1) < 0.001 }
        }
    }
}
