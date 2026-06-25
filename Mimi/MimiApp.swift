import RevenueCat
import CoreText
import SwiftUI

@main
struct MimiApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var conversationStore = ConversationStore()
    @State private var monetizationService = MonetizationService()

    init() {
        BrandFont.register()
        RevenueCatConfiguration.configure()
        AnalyticsService.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    AppTabView()
                        .transition(.opacity)
                } else {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity)
                }
            }
            .environment(conversationStore)
            .environment(monetizationService)
            .preferredColorScheme(.light)
        }
    }
}

private enum BrandFont {
    static func register() {
        guard let url = Bundle.main.url(forResource: "Quicksand", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

@MainActor
enum RevenueCatConfiguration {
    static func configure() {
        guard !Purchases.isConfigured,
              let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

#if DEBUG
        Purchases.logLevel = .debug
#endif
        Purchases.configure(withAPIKey: apiKey)
    }
}
