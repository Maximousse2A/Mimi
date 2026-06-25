import SwiftUI

enum MimiTheme {
    static let background = Color(red: 1.00, green: 0.992, blue: 0.976)
    static let surface = Color(red: 0.984, green: 0.976, blue: 0.961)
    static let surfaceContainer = Color(red: 0.937, green: 0.933, blue: 0.918)
    static let surfaceContainerLowest = Color.white
    static let primary = Color(red: 1.00, green: 0.702, blue: 0.278)
    static let onPrimary = Color(red: 0.439, green: 0.278, blue: 0.00)
    static let primaryInk = Color(red: 0.439, green: 0.278, blue: 0.00)
    static let secondary = Color(red: 1.00, green: 0.961, blue: 0.882)
    static let tertiary = Color(red: 1.00, green: 0.843, blue: 0.00)
    static let onSurface = Color(red: 0.106, green: 0.110, blue: 0.102)
    static let onSurfaceVariant = Color(red: 0.322, green: 0.271, blue: 0.208)
    static let outline = Color(red: 0.518, green: 0.455, blue: 0.388)
    static let outlineVariant = Color(red: 0.839, green: 0.765, blue: 0.690)
    static let shadowTint = Color(red: 0.902, green: 0.835, blue: 0.765)
    static let success = Color(red: 0.439, green: 0.365, blue: 0.00)
    static let error = Color(red: 0.729, green: 0.102, blue: 0.102)

    static let heroGradient = LinearGradient(
        colors: [primary, Color(red: 1.00, green: 0.725, blue: 0.353), tertiary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

}

struct MimiBackground: View {
    var body: some View {
        ZStack {
            MimiTheme.background

            Circle()
                .fill(MimiTheme.secondary.opacity(0.90))
                .frame(width: 360, height: 360)
                .blur(radius: 24)
                .offset(x: 160, y: -330)

            Circle()
                .fill(MimiTheme.tertiary.opacity(0.10))
                .frame(width: 310, height: 310)
                .blur(radius: 30)
                .offset(x: -180, y: 270)

            Circle()
                .fill(MimiTheme.primary.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: 170, y: 410)
        }
        .ignoresSafeArea()
    }
}

struct SoftCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(MimiTheme.surfaceContainerLowest, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MimiTheme.outlineVariant.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: .white.opacity(0.90), radius: 18, x: -8, y: -8)
            .shadow(color: MimiTheme.shadowTint.opacity(0.52), radius: 22, x: 10, y: 12)
    }
}

extension View {
    func softCard(cornerRadius: CGFloat = 32) -> some View {
        modifier(SoftCardModifier(cornerRadius: cornerRadius))
    }
}

extension Font {
    static func mimi(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let textStyle: Font.TextStyle = switch size {
        case 28...: .largeTitle
        case 22..<28: .title2
        case 17..<22: .headline
        case 14..<17: .body
        case 12..<14: .subheadline
        default: .caption
        }

        return .custom("Quicksand", size: size, relativeTo: textStyle)
            .weight(weight)
    }
}
