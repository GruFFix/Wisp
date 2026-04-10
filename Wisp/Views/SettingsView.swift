import SwiftUI
import AppKit
import ServiceManagement

// MARK: - SettingsView

struct SettingsView: View {
    @ObservedObject var settings: DustSettings
    var onClose: () -> Void
    var onCheckForUpdates: () -> Void

    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    private let accent = Color(red: 0.55, green: 0.30, blue: 0.98)

    var body: some View {
        ZStack(alignment: .top) {
            // True black base
            Color(red: 0.051, green: 0.051, blue: 0.051).ignoresSafeArea()

            // Atmospheric glow
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 220
            )
            .frame(height: 220)
            .allowsHitTesting(false)

            // Content
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        themeCard
                        if settings.theme == .custom { customColorCard }
                        parametersCard
                        systemCard
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
                Divider().background(Color.white.opacity(0.06))
                footer
            }
        }
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wisp")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Desktop Particles")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(0.3)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.40))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Theme card

    private var themeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Color Theme")
                HStack(spacing: 0) {
                    ForEach(ColorTheme.allCases) { theme in
                        SwatchDot(theme: theme,
                                  isSelected: settings.theme == theme,
                                  accent: accent)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                                    settings.theme = theme
                                }
                            }
                    }
                }
            }
            .padding(.vertical, 11)
        }
    }

    // MARK: - Custom color card

    private var customColorCard: some View {
        Card {
            VStack(spacing: 0) {
                customColorRow(label: "Color 1", color: Binding(
                    get: { Color(cgColor: settings.customColor1) },
                    set: { settings.customColor1 = NSColor($0).cgColor }
                ))
                CardDivider()
                customColorRow(label: "Color 2", color: Binding(
                    get: { Color(cgColor: settings.customColor2) },
                    set: { settings.customColor2 = NSColor($0).cgColor }
                ))
                CardDivider()
                customColorRow(label: "Color 3", color: Binding(
                    get: { Color(cgColor: settings.customColor3) },
                    set: { settings.customColor3 = NSColor($0).cgColor }
                ))
            }
        }
    }

    private func customColorRow(label: String, color: Binding<Color>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 9))
                .foregroundColor(color.wrappedValue)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.80))
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.vertical, 11)
    }

    // MARK: - Parameters card

    private var parametersCard: some View {
        Card {
            VStack(spacing: 0) {
                ParamSlider(
                    title: "Density", icon: "square.grid.2x2",
                    value: $settings.density, range: 0.2...3.0, accent: accent
                )
                CardDivider()
                ParamSlider(
                    title: "Speed", icon: "arrow.right",
                    value: $settings.speed, range: 0.2...3.0, accent: accent
                )
                CardDivider()
                ParamSlider(
                    title: "Size", icon: "arrow.up.left.and.arrow.down.right",
                    value: $settings.size, range: 0.5...2.0, accent: accent
                )
                CardDivider()
                ParamSlider(
                    title: "Drift", icon: "wind",
                    value: $settings.drift, range: 0.0...3.0, accent: accent
                )
                CardDivider()
                WindRow(windX: $settings.windX, windY: $settings.windY, accent: accent)
                CardDivider()
                ParamToggle(
                    title: "Additive Glow", icon: "sparkle",
                    isOn: $settings.glow, tint: accent
                )
            }
        }
    }

    // MARK: - System card

    private var systemCard: some View {
        Card {
            ParamToggle(
                title: "Launch at Login", icon: "power",
                isOn: $launchAtLogin,
                tint: Color(red: 0.18, green: 0.80, blue: 0.44)
            )
            .onChange(of: launchAtLogin) { newValue in
                do {
                    if newValue { try SMAppService.mainApp.register() }
                    else        { try SMAppService.mainApp.unregister() }
                } catch {
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("v1.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.18))
            Spacer()
            Menu {
                Button("Check for Updates…") { onCheckForUpdates() }
                Divider()
                Button("Quit Wisp") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.22))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

// MARK: - Card container

private struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.11, green: 0.11, blue: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
            )
            .padding(.horizontal, 16)
    }
}

private struct CardDivider: View {
    var body: some View {
        Divider()
            .background(Color.white.opacity(0.05))
            .padding(.leading, 28)
    }
}

private struct Label: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white.opacity(0.25))
            .kerning(1.3)
    }
}

// MARK: - Swatch dot

struct SwatchDot: View {
    let theme: ColorTheme
    let isSelected: Bool
    let accent: Color

    var body: some View {
        ZStack {
            if theme == .custom {
                Circle().fill(Color.white.opacity(0.06))
                Image(systemName: "eyedropper")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.white.opacity(0.30))
            } else {
                let c = theme.swatchColors
                Circle().fill(
                    AngularGradient(
                        colors: c + [c[0]], center: .center,
                        startAngle: .degrees(-90), endAngle: .degrees(270)
                    )
                )
                Circle().fill(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .clear],
                        startPoint: .topLeading, endPoint: .center
                    )
                )
            }
            if isSelected {
                Circle()
                    .strokeBorder(accent, lineWidth: 2.5)
            } else {
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .frame(width: 28, height: 28)
        .scaleEffect(isSelected ? 1.12 : 1.0)
        .shadow(color: isSelected ? accent.opacity(0.6) : .clear, radius: 5, y: 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isSelected)
    }
}

// MARK: - Param slider row

struct ParamSlider: View {
    let title: String
    let icon: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.80))
                Spacer()
                Text(String(format: "%.1f×", value))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(accent)
            }
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Float($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound))
            .tint(accent)
        }
        .padding(.vertical, 11)
    }
}

// MARK: - Param toggle row

struct ParamToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 18)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.80))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(tint)
                .scaleEffect(0.75, anchor: .trailing)
        }
        .padding(.vertical, 11)
    }
}

// MARK: - Wind direction row

struct WindRow: View {
    @Binding var windX: Float
    @Binding var windY: Float
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.left.and.arrow.down.right.circle")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 18)
            Text("Direction")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.80))
            Spacer()
            WindJoystick(windX: $windX, windY: $windY, accent: accent)
                .frame(width: 62, height: 62)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Joystick control
// Drag anywhere inside the circle.  Centre = calm (0,0).
// Distance from centre → wind strength; direction → wind direction.
// Snaps back to centre when released within the dead-zone radius.

struct WindJoystick: View {
    @Binding var windX: Float   // –1…1, right is positive
    @Binding var windY: Float   // –1…1, up   is positive
    let accent: Color

    private let deadZone: CGFloat = 0.15   // normalised radius for centre-snap

    var body: some View {
        GeometryReader { geo in
            let sz = min(geo.size.width, geo.size.height)
            let cx = sz / 2
            let r  = cx - 6

            // Handle position (screen coords: y is flipped vs math-y)
            let hx = cx + r * CGFloat(windX)
            let hy = cx - r * CGFloat(windY)
            let isCentre = CGFloat(windX) == 0 && CGFloat(windY) == 0

            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)

                // Crosshair guides
                Path { p in
                    p.move(to: CGPoint(x: cx, y: 6))
                    p.addLine(to: CGPoint(x: cx, y: sz - 6))
                    p.move(to: CGPoint(x: 6,  y: cx))
                    p.addLine(to: CGPoint(x: sz - 6, y: cx))
                }
                .stroke(Color.white.opacity(0.07), lineWidth: 1)

                // Cardinal dots
                ForEach(0..<4) { i in
                    let ta = CGFloat(i) * .pi / 2
                    let tx = cx + (r - 4) * cos(ta)
                    let ty = cx - (r - 4) * sin(ta)
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 3, height: 3)
                        .position(x: tx, y: ty)
                }

                // Line from centre to handle (hidden when centred)
                if !isCentre {
                    Path { p in
                        p.move(to: CGPoint(x: cx, y: cx))
                        p.addLine(to: CGPoint(x: hx, y: hy))
                    }
                    .stroke(accent.opacity(0.55),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }

                // Centre pip — glows accent when calm, dim otherwise
                Circle()
                    .fill(isCentre ? accent : Color.white.opacity(0.20))
                    .frame(width: isCentre ? 10 : 4, height: isCentre ? 10 : 4)
                    .shadow(color: isCentre ? accent.opacity(0.6) : .clear, radius: 5)
                    .position(x: cx, y: cx)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCentre)

                // Draggable handle (hidden when centred — the pip takes its role)
                if !isCentre {
                    Circle()
                        .fill(accent)
                        .frame(width: 11, height: 11)
                        .shadow(color: accent.opacity(0.55), radius: 5)
                        .position(x: hx, y: hy)
                }
            }
            .frame(width: sz, height: sz)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        var dx = (v.location.x - cx) / r
                        var dy = -(v.location.y - cx) / r   // flip y

                        // Clamp to unit circle
                        let len = sqrt(dx * dx + dy * dy)
                        if len > 1 { dx /= len; dy /= len }

                        // Dead-zone snap to centre
                        if len < deadZone { dx = 0; dy = 0 }

                        windX = Float(dx)
                        windY = Float(dy)
                    }
            )
            // Double-tap to reset to centre
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    windX = 0; windY = 0
                }
            }
        }
    }
}

// MARK: - Visual Effect

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow; v.blendingMode = .withinWindow
        v.state = .active; v.appearance = NSAppearance(named: .darkAqua)
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

