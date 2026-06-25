import SwiftUI
import UIKit

enum MimiImageAsset {
    private static let aliases = [
        "Onboarding Welcome Cat": "Welcome cat",
        "Onboarding Name Cat": "Name cat",
        "Onboarding Translate Cat": "Translate cat",
        "Onboarding Learn Cat": "Learn cat",
        "Onboarding Sounds Cat": "Sounds cat",
        "Onboarding Quiz Cat": "Quiz cat",
        "Onboarding Bell Cat": "Notifications cat",
        "Paywall Crown Cat": "Paywall crown cat"
    ]

    static func image(named name: String) -> UIImage? {
        if let alias = aliases[name], let image = UIImage(named: alias) {
            return image
        }

        return UIImage(named: name)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow)
                .font(.mimi(size: 11, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(title)
                .font(.mimi(size: 34, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .lineSpacing(-2)

            Text(subtitle)
                .font(.mimi(size: 14, weight: .medium))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
        }
        .padding(.horizontal, 20)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.mimi(size: 13, weight: .bold))
                .foregroundStyle(isSelected ? MimiTheme.primaryInk : MimiTheme.onSurface)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(
                    .regular
                        .tint(isSelected ? MimiTheme.primary : MimiTheme.secondary)
                        .interactive(),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }
}

struct CatProfileOption: Identifiable, Hashable {
    let assetName: String
    let fallbackAssetName: String

    var id: String { assetName }

    static let choices = [
        CatProfileOption(assetName: "Profile Cat 1", fallbackAssetName: "Cat Mascot"),
        CatProfileOption(assetName: "Profile Cat 2", fallbackAssetName: "Cat Mascot (4)"),
        CatProfileOption(assetName: "Profile Cat 3", fallbackAssetName: "Cat Mascot (5)"),
        CatProfileOption(assetName: "Profile Cat 4", fallbackAssetName: "Cat Mascot (6)"),
        CatProfileOption(assetName: "Profile Cat 5", fallbackAssetName: "Meow cat 13, 2026 at 11_06_19 AM (1)"),
        CatProfileOption(assetName: "Profile Cat 6", fallbackAssetName: "Meow cat 13, 2026 at 11_06_19 AM (2)")
    ]

    static func fallbackAssetName(for assetName: String) -> String {
        choices.first(where: { $0.assetName == assetName })?.fallbackAssetName ?? "Cat Mascot"
    }

    static func image(for assetName: String) -> UIImage? {
        MimiImageAsset.image(named: assetName)
            ?? MimiImageAsset.image(named: fallbackAssetName(for: assetName))
            ?? MimiImageAsset.image(named: "Cat Mascot")
    }
}

struct CatProfileAvatar: View {
    let assetName: String
    var size: CGFloat = 54
    var showsShadow = true

    private var image: UIImage? {
        CatProfileOption.image(for: assetName)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(MimiTheme.secondary)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .padding(3)
                    .clipShape(.circle)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle()
                .stroke(MimiTheme.surfaceContainerLowest, lineWidth: max(2, size * 0.04))
        }
        .shadow(
            color: showsShadow ? MimiTheme.shadowTint.opacity(0.55) : .clear,
            radius: showsShadow ? size * 0.12 : 0,
            y: showsShadow ? size * 0.07 : 0
        )
        .accessibilityHidden(true)
    }
}

#if DEBUG
struct OnboardingTestButton: View {
    let title: String
    let systemImage: String
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .heavy))

                Text(title)
                    .font(.mimi(size: 12, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(MimiTheme.primaryInk)
            .padding(.horizontal, 13)
            .frame(height: 38)
        }
        .buttonStyle(.glassProminent)
        .tint(MimiTheme.primary)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
#endif
