import SwiftUI
import UIKit

struct SignalCompanionView: View {
    let state: State
    var size: CGFloat = 220
    var assetName: String = "Profile Cat 1"

    private var companionImage: UIImage? {
        CatProfileOption.image(for: assetName)
    }

    enum State {
        case ready
        case listening
        case translated

        var symbol: String {
            "cat.fill"
        }

        var label: String {
            switch self {
            case .ready: L10n.text("Voice signal ready")
            case .listening: L10n.text("Listening for a voice signal")
            case .translated: L10n.text("Voice signal analyzed")
            }
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(MimiTheme.tertiary.opacity(0.10))
                .frame(width: size, height: size)

            Circle()
                .stroke(MimiTheme.primaryInk.opacity(0.10), lineWidth: 1.5)
                .frame(width: size * 0.82, height: size * 0.82)

            Circle()
                .fill(MimiTheme.surfaceContainerLowest)
                .frame(width: size * 0.60, height: size * 0.60)
                .overlay {
                    Circle()
                        .stroke(MimiTheme.outlineVariant.opacity(0.26), lineWidth: 1)
                }
                .shadow(color: .white.opacity(0.90), radius: 16, x: -7, y: -7)
                .shadow(color: MimiTheme.shadowTint.opacity(0.52), radius: 20, x: 9, y: 10)

            CompanionImage(
                image: companionImage,
                fallbackSymbol: state.symbol,
                size: size
            )

            SignalDots(size: size)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.label)
    }
}

private struct CompanionImage: View {
    let image: UIImage?
    let fallbackSymbol: String
    let size: CGFloat

    private var badgeSize: CGFloat { size * 0.45 }
    private var imageSize: CGFloat { badgeSize - size * 0.036 }

    var body: some View {
        ZStack {
            Circle()
                .fill(MimiTheme.primary)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(.circle)
            } else {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.19, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(MimiTheme.primaryInk, MimiTheme.secondary)
            }
        }
        .frame(width: badgeSize, height: badgeSize)
        .clipShape(.circle)
        .overlay {
            Circle()
                .stroke(MimiTheme.surfaceContainerLowest.opacity(0.82), lineWidth: max(2, size * 0.014))
        }
        .shadow(color: MimiTheme.primary.opacity(0.22), radius: size * 0.05, y: size * 0.025)
    }
}

private struct SignalDots: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            dot(MimiTheme.primary, x: -0.39, y: -0.12, scale: 0.070)
            dot(MimiTheme.tertiary, x: 0.36, y: -0.25, scale: 0.050)
            dot(MimiTheme.success, x: 0.38, y: 0.23, scale: 0.064)
            dot(MimiTheme.primaryInk, x: -0.28, y: 0.34, scale: 0.044)
        }
    }

    private func dot(_ color: Color, x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.78))
            .frame(width: size * scale, height: size * scale)
            .offset(x: size * x, y: size * y)
    }
}

struct TopicVisual: View {
    let symbol: String
    let tint: Color
    var height: CGFloat = 150

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.20), MimiTheme.secondary, MimiTheme.surfaceContainerLowest],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(.white.opacity(0.72), lineWidth: 1.5)
                .frame(width: height * 0.78, height: height * 0.78)
                .offset(x: height * 0.62, y: -height * 0.22)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(MimiTheme.surfaceContainerLowest)
                .frame(width: height * 0.70, height: height * 0.70)
                .rotationEffect(.degrees(-8))
                .shadow(color: MimiTheme.shadowTint.opacity(0.44), radius: 18, x: 8, y: 9)

            Image(systemName: symbol)
                .font(.system(size: height * 0.30, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
        }
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }
}
