import AmplitudeSwift
import Foundation

@MainActor
enum AnalyticsService {
    private static var amplitude: Amplitude?

    static func configure() {
        guard amplitude == nil,
              let rawAPIKey = Bundle.main.object(forInfoDictionaryKey: "AmplitudeAPIKey") as? String else {
            return
        }

        let apiKey = rawAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { return }

        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))
    }

    static func trackPageViewed(_ pageName: String) {
        track(
            eventType: "page_viewed",
            eventProperties: [
                "page_name": pageName
            ]
        )
    }

    static func trackButtonClicked(_ buttonName: String, pageName: String) {
        track(
            eventType: "button_clicked",
            eventProperties: [
                "button_name": buttonName,
                "page_name": pageName
            ]
        )
    }

    private static func track(eventType: String, eventProperties: [String: Any]? = nil) {
        amplitude?.track(eventType: eventType, eventProperties: eventProperties)
    }
}
