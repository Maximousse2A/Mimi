import SwiftUI

struct TranslatorOrb: View {
    let isListening: Bool
    let isCompact: Bool

    @State private var pulse = false

    private var size: CGFloat { isCompact ? 118 : 150 }

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        MimiTheme.primary.opacity(isListening ? 0.18 - Double(index) * 0.035 : 0.07),
                        lineWidth: 2
                    )
                    .frame(width: size + CGFloat(index * 30), height: size + CGFloat(index * 30))
                    .scaleEffect(isListening && pulse ? 1.10 : 0.94)
                    .opacity(isListening ? 1 : 0.65)
                    .animation(
                        .easeOut(duration: 1.15)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.16),
                        value: pulse
                    )
            }

            Circle()
                .fill(MimiTheme.heroGradient)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.45), lineWidth: 1.5)
                        .padding(5)
                }
                .shadow(color: MimiTheme.primary.opacity(isListening ? 0.46 : 0.28), radius: isListening ? 30 : 22, y: 14)
                .scaleEffect(isListening ? 1.05 : 1)

            VStack(spacing: isCompact ? 6 : 9) {
                WaveformView(isActive: isListening, width: isCompact ? 54 : 70)

                Text(isListening ? L10n.text("Listening...") : L10n.text("Hold to analyze"))
                    .font(.mimi(size: isCompact ? 12 : 14, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .multilineTextAlignment(.center)
            }
        }
        .contentShape(.circle)
        .onAppear { pulse = true }
        .animation(.spring(response: 0.34, dampingFraction: 0.68), value: isListening)
    }
}

private struct WaveformView: View {
    let isActive: Bool
    let width: CGFloat

    @State private var animates = false

    var body: some View {
        Group {
            if isActive {
                HStack(alignment: .center, spacing: width * 0.07) {
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(MimiTheme.primaryInk)
                            .frame(
                                width: width * 0.07,
                                height: barHeight(for: index)
                            )
                            .animation(
                                .easeInOut(duration: 0.42 + Double(index) * 0.06)
                                    .repeatForever(autoreverses: true),
                                value: animates
                            )
                    }
                }
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: width * 0.48, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
            }
        }
        .frame(width: width, height: width * 0.55)
        .onAppear { animates = true }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let resting: [CGFloat] = [0.18, 0.34, 0.52, 0.34, 0.18]
        let active: [CGFloat] = [0.52, 0.78, 0.34, 0.92, 0.60]
        let value = isActive && animates ? active[index] : resting[index]
        return width * value
    }
}
