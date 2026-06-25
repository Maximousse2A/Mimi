import Foundation

enum CatTranslationScenario: String, CaseIterable {
    case hungry
    case attention
    case playful
    case affection
    case curious
    case calm
    case night
    case morning
    case evening
    case repeated
}

enum CatTranslationVoice: String, CaseIterable {
    case warm
    case playful
    case direct

    init(profileValue: String) {
        self = CatTranslationVoice(rawValue: profileValue) ?? .warm
    }
}

struct CatTranslationLine: Equatable {
    let key: String
    let voice: CatTranslationVoice

    init(_ key: String, voice: CatTranslationVoice) {
        self.key = key
        self.voice = voice
    }
}

enum CatTranslationCopy {
    static let recentTextWindow = 12

    static var allLines: [CatTranslationLine] {
        CatTranslationScenario.allCases.flatMap(lines(for:))
    }

    static func lines(for scenario: CatTranslationScenario) -> [CatTranslationLine] {
        catalog[scenario] ?? []
    }

    static func localizedLine(
        for scenario: CatTranslationScenario,
        capture: RecordedAudioCapture,
        history: [CatConversationMessage],
        now: Date,
        profile: CatTranslationProfile
    ) -> String {
        let lines = lines(for: scenario)
        guard !lines.isEmpty else {
            return L10n.catLine("Just saying hello.")
        }

        let preferredVoice = CatTranslationVoice(profileValue: profile.translationTone)
        let recentTexts = Set(history.suffix(recentTextWindow).map(\.translationText))
        let preferredLines = lines.filter { $0.voice == preferredVoice }
        let freshPreferredLines = preferredLines.filter {
            !recentTexts.contains(L10n.catLine($0.key))
        }
        let freshLines = lines.filter {
            !recentTexts.contains(L10n.catLine($0.key))
        }

        let candidates: [CatTranslationLine]
        if !freshPreferredLines.isEmpty {
            candidates = freshPreferredLines
        } else if !freshLines.isEmpty {
            candidates = freshLines
        } else if !preferredLines.isEmpty {
            candidates = preferredLines
        } else {
            candidates = lines
        }

        let seed = selectionSeed(
            scenario: scenario,
            capture: capture,
            historyCount: history.count,
            now: now
        )
        let selectedLine = candidates[Int(seed % UInt64(candidates.count))]
        return L10n.catLine(selectedLine.key)
    }

    private static func selectionSeed(
        scenario: CatTranslationScenario,
        capture: RecordedAudioCapture,
        historyCount: Int,
        now: Date
    ) -> UInt64 {
        var seed: UInt64 = 14_695_981_039_346_656_037

        func mix(_ value: Int) {
            seed ^= UInt64(bitPattern: Int64(value))
            seed &*= 1_099_511_628_211
        }

        for byte in scenario.rawValue.utf8 {
            mix(Int(byte))
        }

        mix(Int((capture.duration * 100).rounded()))
        mix(Int((capture.analysis.averagePower * 10).rounded()))
        mix(Int((capture.analysis.peakPower * 10).rounded()))
        mix(capture.analysis.peakCount)
        mix(capture.analysis.silenceGapCount)
        mix(Int((now.timeIntervalSinceReferenceDate / 5).rounded(.down)))
        mix(historyCount * 31)
        return seed
    }

    private static let catalog: [CatTranslationScenario: [CatTranslationLine]] = [
        .hungry: [
            .init("A little snack would be lovely.", voice: .warm),
            .init("My bowl feels strangely empty.", voice: .warm),
            .init("Could we discuss the menu?", voice: .warm),
            .init("I saved room for treats.", voice: .warm),
            .init("The bowl has filed a complaint.", voice: .playful),
            .init("Snack alert: supplies are running low.", voice: .playful),
            .init("The kitchen is calling my name.", voice: .playful),
            .init("My dinner appears to be late.", voice: .playful),
            .init("Food, please. Thank you.", voice: .direct),
            .init("I would like a snack.", voice: .direct),
            .init("Please inspect the bowl.", voice: .direct),
            .init("This is a food request.", voice: .direct)
        ],
        .attention: [
            .init("Can I have some attention?", voice: .warm),
            .init("Come sit with me.", voice: .warm),
            .init("I need my favorite human.", voice: .warm),
            .init("A cuddle meeting is requested.", voice: .warm),
            .init("Hello? Your supervisor is calling.", voice: .playful),
            .init("I scheduled us some attention.", voice: .playful),
            .init("Please admire me immediately.", voice: .playful),
            .init("Your cat requires an audience.", voice: .playful),
            .init("Look at me, please.", voice: .direct),
            .init("I need your attention.", voice: .direct),
            .init("Come here for a moment.", voice: .direct),
            .init("Please check what I need.", voice: .direct)
        ],
        .playful: [
            .init("Want to play with me?", voice: .warm),
            .init("Let's chase something together.", voice: .warm),
            .init("I have energy to share.", voice: .warm),
            .init("Playtime would make me happy.", voice: .warm),
            .init("My paws have chosen chaos.", voice: .playful),
            .init("Release the tiny hunter.", voice: .playful),
            .init("I challenge you to a duel.", voice: .playful),
            .init("The zoomies need a sponsor.", voice: .playful),
            .init("Bring me a toy.", voice: .direct),
            .init("It is time to play.", voice: .direct),
            .init("Let's move.", voice: .direct),
            .init("I want some action.", voice: .direct)
        ],
        .affection: [
            .init("I'm glad you're close.", voice: .warm),
            .init("Stay here a little longer.", voice: .warm),
            .init("You make this spot better.", voice: .warm),
            .init("This is our cozy moment.", voice: .warm),
            .init("I permit one tiny cuddle.", voice: .playful),
            .init("Congratulations, you are my person.", voice: .playful),
            .init("Your presence has been approved.", voice: .playful),
            .init("I ordered extra affection.", voice: .playful),
            .init("Stay close.", voice: .direct),
            .init("Pet me gently.", voice: .direct),
            .init("I feel safe with you.", voice: .direct),
            .init("This is a friendly hello.", voice: .direct)
        ],
        .curious: [
            .init("What was that?", voice: .warm),
            .init("Something interesting just happened.", voice: .warm),
            .init("I need to inspect that.", voice: .warm),
            .init("Did you hear that too?", voice: .warm),
            .init("Suspicious. I must investigate.", voice: .playful),
            .init("The plot has suddenly thickened.", voice: .playful),
            .init("Tiny detective reporting for duty.", voice: .playful),
            .init("That requires a full inspection.", voice: .playful),
            .init("I noticed something.", voice: .direct),
            .init("Let me check this.", voice: .direct),
            .init("Something changed nearby.", voice: .direct),
            .init("I am investigating.", voice: .direct)
        ],
        .calm: [
            .init("Just saying hello.", voice: .warm),
            .init("Everything feels nice and quiet.", voice: .warm),
            .init("I'm here with you.", voice: .warm),
            .init("This is a peaceful little chat.", voice: .warm),
            .init("Official cat status: still adorable.", voice: .playful),
            .init("Nothing urgent. Just excellent commentary.", voice: .playful),
            .init("I had a thought. Meow.", voice: .playful),
            .init("This meeting could have been silent.", voice: .playful),
            .init("Checking in.", voice: .direct),
            .init("All good here.", voice: .direct),
            .init("I am nearby.", voice: .direct),
            .init("No urgent request.", voice: .direct)
        ],
        .night: [
            .init("Are you awake too?", voice: .warm),
            .init("The house sounds different tonight.", voice: .warm),
            .init("Stay near me for a moment.", voice: .warm),
            .init("I have a midnight thought.", voice: .warm),
            .init("Night shift cat reporting in.", voice: .playful),
            .init("The darkness requires commentary.", voice: .playful),
            .init("Midnight meeting. Attendance mandatory.", voice: .playful),
            .init("I brought the midnight news.", voice: .playful),
            .init("Wake up, please.", voice: .direct),
            .init("I need something tonight.", voice: .direct),
            .init("Come check on me.", voice: .direct),
            .init("This is a nighttime call.", voice: .direct)
        ],
        .morning: [
            .init("Good morning, sleepy human.", voice: .warm),
            .init("Ready to start our day?", voice: .warm),
            .init("The morning needs us.", voice: .warm),
            .init("I came to wake you gently.", voice: .warm),
            .init("Breakfast has entered the chat.", voice: .playful),
            .init("Sun's up. Bowl's empty.", voice: .playful),
            .init("Your furry alarm is working.", voice: .playful),
            .init("Morning management has arrived.", voice: .playful),
            .init("It is morning.", voice: .direct),
            .init("Please get up.", voice: .direct),
            .init("Breakfast time?", voice: .direct),
            .init("Let's start the day.", voice: .direct)
        ],
        .evening: [
            .init("Time to settle in together.", voice: .warm),
            .init("How about dinner and cuddles?", voice: .warm),
            .init("The evening routine can begin.", voice: .warm),
            .init("Let's make the room cozy.", voice: .warm),
            .init("Evening agenda: snacks, then chaos.", voice: .playful),
            .init("Dinner first. Zoomies later.", voice: .playful),
            .init("The night shift starts now.", voice: .playful),
            .init("I vote for couch time.", voice: .playful),
            .init("It is dinner time.", voice: .direct),
            .init("Let's do our evening routine.", voice: .direct),
            .init("Please check my bowl.", voice: .direct),
            .init("I am ready to settle.", voice: .direct)
        ],
        .repeated: [
            .init("I'm saying it with emphasis.", voice: .warm),
            .init("I still have something to say.", voice: .warm),
            .init("Just making sure you heard.", voice: .warm),
            .init("The request remains politely active.", voice: .warm),
            .init("Second meow, same management issue.", voice: .playful),
            .init("Please reread my previous memo.", voice: .playful),
            .init("I have added dramatic emphasis.", voice: .playful),
            .init("This message now has priority.", voice: .playful),
            .init("I am asking again.", voice: .direct),
            .init("The request is still active.", voice: .direct),
            .init("Please listen.", voice: .direct),
            .init("Same request, one more time.", voice: .direct)
        ]
    ]
}
