import Foundation
import GoogleMobileAds
import Observation
import RevenueCat
import UserMessagingPlatform

enum MonetizationEvent: String, CaseIterable {
    case translationCompleted
    case quizCompleted
    case soundPlayed
    case articleRead

    var threshold: Int {
        switch self {
        case .translationCompleted:
            2
        case .quizCompleted:
            1
        case .soundPlayed:
            4
        case .articleRead:
            3
        }
    }

    fileprivate var counterKey: String {
        "adFrequency.\(rawValue)"
    }
}

@MainActor
@Observable
final class MonetizationService: NSObject {
    private(set) var isPrivacyOptionsRequired = false
    private(set) var canShowBanner = false

    private var interstitialAd: InterstitialAd?
    private var interstitialLoadedAt: Date?
    private var isPreparing = false
    private var hasPrepared = false
    private var hasStartedAds = false
    private var isLoadingInterstitial = false
    private var isPresentingInterstitial = false
    private var pendingCounterReset: MonetizationEvent?

    private static let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    private static let maximumAdAge: TimeInterval = 55 * 60

    func prepare() async {
        guard !hasPrepared, !isPreparing else { return }

        isPreparing = true
        defer { isPreparing = false }

        guard await premiumAccessStatus() == false else {
            canShowBanner = false
            resetEventCounters()
            return
        }

        do {
            try await requestConsentInformationUpdate()
            refreshPrivacyOptionsRequirement()
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
#if DEBUG
            print("Ad consent preparation failed: \(error.localizedDescription)")
#endif
        }

        refreshPrivacyOptionsRequirement()
        await startAdsIfPermitted()
        hasPrepared = true
    }

    @discardableResult
    func record(_ event: MonetizationEvent) async -> Bool {
        guard await premiumAccessStatus() == false else {
            canShowBanner = false
            resetEventCounters()
            return false
        }

        if !hasPrepared {
            await prepare()
        }

        let defaults = UserDefaults.standard
        let count = min(defaults.integer(forKey: event.counterKey) + 1, event.threshold)
        defaults.set(count, forKey: event.counterKey)

        guard count >= event.threshold,
              ConsentInformation.shared.canRequestAds else {
            return false
        }

        if isInterstitialExpired {
            interstitialAd = nil
            interstitialLoadedAt = nil
        }

        guard !isPresentingInterstitial, let interstitialAd else {
            await loadInterstitialIfNeeded()
            return false
        }

        pendingCounterReset = event
        isPresentingInterstitial = true
        interstitialAd.present(from: nil)
        return true
    }

    func refreshAdEligibility() async {
        guard await premiumAccessStatus() == false else {
            canShowBanner = false
            resetEventCounters()
            return
        }

        if !hasPrepared {
            await prepare()
        } else {
            await startAdsIfPermitted()
        }
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
#if DEBUG
            print("Privacy options presentation failed: \(error.localizedDescription)")
#endif
        }

        refreshPrivacyOptionsRequirement()
        await startAdsIfPermitted()
    }

    var bannerAdUnitID: String? {
#if DEBUG
        return Self.testBannerAdUnitID
#else
        guard let rawValue = Bundle.main.object(
            forInfoDictionaryKey: "AdMobBannerAdUnitID"
        ) as? String else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
#endif
    }

    private var isInterstitialExpired: Bool {
        guard let interstitialLoadedAt else { return false }
        return Date().timeIntervalSince(interstitialLoadedAt) >= Self.maximumAdAge
    }

    private var interstitialAdUnitID: String? {
#if DEBUG
        return Self.testInterstitialAdUnitID
#else
        guard let rawValue = Bundle.main.object(
            forInfoDictionaryKey: "AdMobInterstitialAdUnitID"
        ) as? String else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
#endif
    }

    private func requestConsentInformationUpdate() async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(
                with: RequestParameters()
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func refreshPrivacyOptionsRequirement() {
        isPrivacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startAdsIfPermitted() async {
        guard ConsentInformation.shared.canRequestAds else {
            canShowBanner = false
            return
        }

        if !hasStartedAds {
            await MobileAds.shared.start()
            hasStartedAds = true
        }

        canShowBanner = bannerAdUnitID != nil
        await loadInterstitialIfNeeded()
    }

    private func loadInterstitialIfNeeded() async {
        guard hasStartedAds,
              !isLoadingInterstitial,
              !isPresentingInterstitial,
              interstitialAd == nil,
              let interstitialAdUnitID else {
            return
        }

        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }

        do {
            let ad = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            interstitialAd = ad
            interstitialLoadedAt = Date()
        } catch {
            interstitialAd = nil
            interstitialLoadedAt = nil
#if DEBUG
            print("Interstitial loading failed: \(error.localizedDescription)")
#endif
        }
    }

    private func resetEventCounters() {
        let defaults = UserDefaults.standard
        for event in MonetizationEvent.allCases {
            defaults.removeObject(forKey: event.counterKey)
        }
    }

    private func premiumAccessStatus() async -> Bool? {
        guard Purchases.isConfigured else { return false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return !customerInfo.entitlements.active.isEmpty
        } catch {
#if DEBUG
            print("Premium status refresh failed: \(error.localizedDescription)")
#endif
            return nil
        }
    }
}

extension MonetizationService: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if let pendingCounterReset {
            UserDefaults.standard.removeObject(forKey: pendingCounterReset.counterKey)
        }
        pendingCounterReset = nil
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        interstitialAd = nil
        interstitialLoadedAt = nil
        isPresentingInterstitial = false
        pendingCounterReset = nil

#if DEBUG
        print("Interstitial presentation failed: \(error.localizedDescription)")
#endif

        Task {
            await loadInterstitialIfNeeded()
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        interstitialLoadedAt = nil
        isPresentingInterstitial = false
        pendingCounterReset = nil

        Task {
            await loadInterstitialIfNeeded()
        }
    }
}
