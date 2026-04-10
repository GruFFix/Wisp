#!/usr/bin/swift
import AppKit
import CoreGraphics

let size: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// --- Background: dark #0D0D12 ---
ctx.setFillColor(CGColor(red: 0.051, green: 0.051, blue: 0.071, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// --- Radial glow: purple bloom center ---
let colors  = [CGColor(red: 0.48, green: 0.22, blue: 1.0, alpha: 0.45),
               CGColor(red: 0.48, green: 0.22, blue: 1.0, alpha: 0.0)] as CFArray
let locs: [CGFloat] = [0, 1]
let space  = CGColorSpaceCreateDeviceRGB()
let grad   = CGGradient(colorsSpace: space, colors: colors, locations: locs)!
let center = CGPoint(x: size / 2, y: size / 2)
ctx.drawRadialGradient(grad, startCenter: center, startRadius: 0,
                       endCenter: center, endRadius: size * 0.55, options: [])

// --- sparkles SF Symbol ---
let cfg  = NSImage.SymbolConfiguration(pointSize: 460, weight: .thin)
let img  = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)!
              .withSymbolConfiguration(cfg)!

// Tint: white with purple tint
let tinted = NSImage(size: img.size)
tinted.lockFocus()
NSColor(red: 0.88, green: 0.78, blue: 1.0, alpha: 1).set()
img.draw(at: .zero, from: .zero, operation: .sourceAtop, fraction: 1)
NSColor(white: 1, alpha: 0.9).set()
img.draw(at: .zero, from: .zero, operation: .sourceAtop, fraction: 0.6)
tinted.unlockFocus()

let drawRect = NSRect(
    x: (size - img.size.width)  / 2,
    y: (size - img.size.height) / 2,
    width:  img.size.width,
    height: img.size.height)
tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)

// --- Subtle outer glow ring ---
let ringColors = [CGColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.0),
                  CGColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.18),
                  CGColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.0)] as CFArray
let ringLocs: [CGFloat] = [0, 0.85, 1.0]
let ringGrad = CGGradient(colorsSpace: space, colors: ringColors, locations: ringLocs)!
ctx.drawRadialGradient(ringGrad, startCenter: center, startRadius: 0,
                       endCenter: center, endRadius: size * 0.52, options: [])

// --- Save PNG ---
let png  = rep.representation(using: .png, properties: [:])!
let url  = URL(fileURLWithPath: "icon_1024.png")
try! png.write(to: url)
print("✅ Saved icon_1024.png (\(Int(size))×\(Int(size)))")
