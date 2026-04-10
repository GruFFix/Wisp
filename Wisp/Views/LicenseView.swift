import SwiftUI

struct LicenseView: View {
    var onActivated: () -> Void

    @State private var key:      String = ""
    @State private var loading:  Bool   = false
    @State private var errorMsg: String = ""

    private let accent = Color(red: 0.55, green: 0.30, blue: 0.98)

    var body: some View {
        ZStack {
            Color(red: 0.051, green: 0.051, blue: 0.051).ignoresSafeArea()

            RadialGradient(
                colors: [accent.opacity(0.20), .clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0, endRadius: 200
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {

                // Icon
                if let icon = NSImage(named: "AppIcon") {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: accent.opacity(0.4), radius: 16, y: 4)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                }

                Text("Activate Wisp")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Enter your license key from Gumroad")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.40))
                    .padding(.top, 4)
                    .padding(.bottom, 24)

                // Key field
                TextField("XXXX-XXXX-XXXX-XXXX", text: $key)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .onSubmit { activate() }

                // Error
                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 1, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Activate button
                Button(action: activate) {
                    ZStack {
                        if loading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .tint(.white)
                        } else {
                            Text("Activate")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(loading || key.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                // Buy link
                Button("Don't have a license? Buy on Gumroad →") {
                    if let url = URL(string: "https://YOUR_GUMROAD_LINK") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(accent.opacity(0.70))
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .preferredColorScheme(.dark)
    }

    private func activate() {
        guard !loading else { return }
        loading  = true
        errorMsg = ""

        LicenseManager.shared.activate(key: key) { result in
            loading = false
            switch result {
            case .success:
                onActivated()
            case .failure(let err):
                errorMsg = err.message
            }
        }
    }
}
