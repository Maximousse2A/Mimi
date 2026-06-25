import GoogleMobileAds
import SwiftUI

struct AppTabView: View {
    @Environment(MonetizationService.self) private var monetizationService
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .translate

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                Tab(L10n.text("Analyze"), systemImage: "waveform.badge.mic", value: .translate) {
                    HomeView()
                }

                Tab(L10n.text("Learn"), systemImage: "book.pages.fill", value: .learn) {
                    LearnView()
                }

                Tab(L10n.text("Sounds"), systemImage: "speaker.wave.3.fill", value: .sounds) {
                    SoundsView()
                }

                Tab(L10n.text("Quiz"), systemImage: "questionmark.circle.fill", value: .quiz) {
                    QuizView()
                }
            }
            .tint(MimiTheme.primary)

            if monetizationService.canShowBanner,
               let bannerAdUnitID = monetizationService.bannerAdUnitID {
                BottomBannerAdView(adUnitID: bannerAdUnitID)
            }
        }
        .task {
            await monetizationService.refreshAdEligibility()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }

            Task {
                await monetizationService.refreshAdEligibility()
            }
        }
#if DEBUG
        .safeAreaInset(edge: .top, alignment: .trailing, spacing: 0) {
            OnboardingTestButton(
                title: L10n.text("Replay onboarding"),
                systemImage: "arrow.counterclockwise",
                accessibilityIdentifier: "debug.replayOnboarding"
            ) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    hasCompletedOnboarding = false
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
#endif
    }
}

private struct BottomBannerAdView: View {
    let adUnitID: String

    @State private var isLoaded = false

    var body: some View {
        BannerViewContainer(adUnitID: adUnitID, isLoaded: $isLoaded)
            .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
            .frame(maxWidth: .infinity)
            .frame(height: isLoaded ? AdSizeBanner.size.height : 0)
            .background(MimiTheme.surfaceContainerLowest)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: isLoaded)
            .accessibilityIdentifier("admob.bottomBanner")
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    @Binding var isLoaded: Bool

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        guard bannerView.adUnitID != adUnitID else { return }

        isLoaded = false
        bannerView.adUnitID = adUnitID
        bannerView.load(Request())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        private var isLoaded: Binding<Bool>

        init(isLoaded: Binding<Bool>) {
            self.isLoaded = isLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            isLoaded.wrappedValue = true
        }

        func bannerView(
            _ bannerView: BannerView,
            didFailToReceiveAdWithError error: Error
        ) {
            isLoaded.wrappedValue = false

#if DEBUG
            print("Banner loading failed: \(error.localizedDescription)")
#endif
        }
    }
}

private enum AppTab: Hashable {
    case translate
    case learn
    case sounds
    case quiz
}

#Preview {
    AppTabView()
        .environment(ConversationStore.preview)
        .environment(MonetizationService())
}
