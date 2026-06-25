import CoreGraphics
import XCTest
@testable import Mimi

final class CatTranslationEngineTests: XCTestCase {
    func testFreeAdFrequencyThresholds() {
        XCTAssertEqual(MonetizationEvent.translationCompleted.threshold, 2)
        XCTAssertEqual(MonetizationEvent.quizCompleted.threshold, 1)
        XCTAssertEqual(MonetizationEvent.soundPlayed.threshold, 4)
        XCTAssertEqual(MonetizationEvent.articleRead.threshold, 3)
    }

    func testQuizBankContainsFifteenQuestionsPerTopic() {
        XCTAssertEqual(QuizContent.topics.count, 4)
        XCTAssertEqual(QuizContent.allQuestions.count, 60)
        XCTAssertEqual(Set(QuizContent.allQuestions.map(\.id)).count, 60)

        for topic in QuizContent.topics {
            XCTAssertEqual(topic.questions.count, 15, "\(topic.id) should contain 15 questions")

            for question in topic.questions {
                XCTAssertEqual(question.answers.count, 4)
                XCTAssertTrue(question.answers.indices.contains(question.correctAnswerIndex))
            }
        }
    }

    func testDailyQuizDoesNotRepeatBeforeTheWholeBankHasAppeared() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let startDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))

        let firstCycle = (0..<QuizContent.allQuestions.count).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startDate) ?? startDate
            return QuizContent.dailyQuestion(on: date, calendar: calendar).id
        }

        XCTAssertEqual(Set(firstCycle).count, QuizContent.allQuestions.count)

        let nextCycleDate = try XCTUnwrap(
            calendar.date(byAdding: .day, value: QuizContent.allQuestions.count, to: startDate)
        )
        XCTAssertEqual(
            QuizContent.dailyQuestion(on: nextCycleDate, calendar: calendar).id,
            try XCTUnwrap(firstCycle.first)
        )
    }

    func testSoftLongSignalReadsAsHappyContactPhrase() {
        let analysis = AudioSignalAnalysis(
            duration: 5.2,
            powerSamples: Array(repeating: -46, count: 70),
            normalizedSamples: Array(repeating: 0.22, count: 70)
        )

        XCTAssertEqual(analysis.vocalPattern, .sustainedCall)
        XCTAssertEqual(analysis.signalQuality, .clear)

        let message = CatTranslationEngine.makeMessage(
            from: capture(duration: 5.2, analysis: analysis),
            catName: "Mimi",
            history: [],
            now: dateAt(hour: 15),
            profile: profile()
        )

        XCTAssertEqual(message.detectedMood, CatMood.affection.rawValue)
        XCTAssertTrue(
            CatTranslationCopy.lines(for: .affection)
                .map { L10n.catLine($0.key) }
                .contains(message.translationText)
        )
        XCTAssertEqual(message.confidence, "Medium confidence")
        XCTAssertFalse(message.evidenceNotes.isEmpty)
    }

    func testRepeatedStrongSignalDuringMealWindowReadsAsHungryPhrase() {
        let analysis = AudioSignalAnalysis(
            duration: 2.6,
            powerSamples: [-55, -18, -18, -55, -55, -55, -17, -18, -55, -55, -55, -16, -17, -55],
            normalizedSamples: [0.10, 0.70, 0.72, 0.10, 0.10, 0.10, 0.74, 0.71, 0.10, 0.10, 0.10, 0.78, 0.74, 0.10]
        )

        XCTAssertEqual(analysis.vocalPattern, .repeatedCall)
        XCTAssertGreaterThanOrEqual(analysis.silenceGapCount, 2)

        let message = CatTranslationEngine.makeMessage(
            from: capture(duration: 2.6, analysis: analysis),
            catName: "Mimi",
            history: [],
            now: dateAt(hour: 12),
            profile: profile()
        )

        XCTAssertEqual(message.detectedMood, CatMood.hungry.rawValue)
        XCTAssertTrue(
            CatTranslationCopy.lines(for: .hungry)
                .map { L10n.catLine($0.key) }
                .contains(message.translationText)
        )
        XCTAssertTrue(message.evidenceNotes.contains("Time of day may influence this read"))
    }

    func testSimilarRecentSignalGetsFreshFollowUpLine() {
        let analysis = AudioSignalAnalysis(
            duration: 2.7,
            powerSamples: [-55, -18, -18, -55, -55, -55, -17, -18, -55, -55, -55, -16, -17, -55],
            normalizedSamples: [0.10, 0.70, 0.72, 0.10, 0.10, 0.10, 0.74, 0.71, 0.10, 0.10, 0.10, 0.78, 0.74, 0.10]
        )
        let first = CatTranslationEngine.makeMessage(
            from: capture(duration: 2.7, analysis: analysis),
            catName: "Mimi",
            history: [],
            now: dateAt(hour: 15),
            profile: profile()
        )
        let second = CatTranslationEngine.makeMessage(
            from: capture(duration: 2.8, analysis: analysis),
            catName: "Mimi",
            history: [first],
            now: first.createdAt.addingTimeInterval(45),
            profile: profile()
        )

        XCTAssertNotEqual(second.translationText, first.translationText)
        XCTAssertTrue(
            CatTranslationCopy.lines(for: .repeated)
                .map { L10n.catLine($0.key) }
                .contains(second.translationText)
        )
        XCTAssertTrue(second.evidenceNotes.contains("Similar to a recent recording"))
        XCTAssertEqual(second.interpretationDetail, "Similar to a recent recording")
    }

    func testTranslationCatalogHasAtLeastOneHundredUniqueLines() {
        let lines = CatTranslationCopy.allLines

        XCTAssertGreaterThanOrEqual(lines.count, 100)
        XCTAssertEqual(Set(lines.map(\.key)).count, lines.count)

        for scenario in CatTranslationScenario.allCases {
            let scenarioLines = CatTranslationCopy.lines(for: scenario)
            XCTAssertEqual(scenarioLines.count, 12)

            for voice in CatTranslationVoice.allCases {
                XCTAssertEqual(scenarioLines.filter { $0.voice == voice }.count, 4)
            }
        }
    }

    func testRecentTranslationLinesAreAvoided() {
        let analysis = AudioSignalAnalysis(
            duration: 2.2,
            powerSamples: Array(repeating: -44, count: 30),
            normalizedSamples: Array(repeating: 0.27, count: 30)
        )
        let recordedCapture = capture(duration: 2.2, analysis: analysis)
        let start = dateAt(hour: 15)
        var history: [CatConversationMessage] = []

        for index in 0..<8 {
            let message = CatTranslationEngine.makeMessage(
                from: recordedCapture,
                catName: "Mimi",
                history: history,
                now: start.addingTimeInterval(Double(index) * 130),
                profile: profile()
            )
            history.append(message)
        }

        XCTAssertEqual(Set(history.map(\.translationText)).count, history.count)
    }

    func testLegacyMessageDecodesWithoutInterpretationFields() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "createdAt": 0,
          "audioFileName": "legacy.m4a",
          "duration": 2.4,
          "soundSummary": "2.4s animated meow, 3 louder peaks",
          "translationText": "Legacy translation",
          "confidence": "Curious read",
          "detectedMood": "Curious",
          "waveformLevels": [0.2, 0.4]
        }
        """

        let message = try JSONDecoder().decode(CatConversationMessage.self, from: Data(json.utf8))

        XCTAssertEqual(message.kind, .audio)
        XCTAssertEqual(message.translationText, "Legacy translation")
        XCTAssertEqual(message.interpretationDetail, "")
        XCTAssertEqual(message.evidenceNotes, [])
    }

    func testPhotoMessageEncodesAndDecodesVisualAnalysis() throws {
        let analysis = sampleVisualAnalysis()
        let message = CatConversationMessage(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            kind: .photo,
            createdAt: Date(timeIntervalSince1970: 10),
            photoFileName: "cat-photo.jpg",
            soundSummary: "On-device photo check",
            translationText: analysis.headline,
            confidence: analysis.confidence,
            detectedMood: "Visual",
            interpretationDetail: analysis.interpretation,
            evidenceNotes: ["tail: raised"],
            visualAnalysis: analysis
        )

        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(CatConversationMessage.self, from: data)

        XCTAssertEqual(decoded.kind, .photo)
        XCTAssertEqual(decoded.photoFileName, "cat-photo.jpg")
        XCTAssertEqual(decoded.visualAnalysis, analysis)
        XCTAssertEqual(decoded.audioFileName, "")
        XCTAssertEqual(decoded.duration, 0)
    }

    func testVisualAnalysisResultDecodesBackendJSON() throws {
        let result = try JSONDecoder().decode(VisualAnalysisResult.self, from: Data(sampleVisualAnalysisJSON.utf8))

        XCTAssertEqual(result.headline, "Tail is raised and ears look neutral")
        XCTAssertEqual(result.observations.count, 2)
        XCTAssertEqual(result.observations.first?.category, "tail")
        XCTAssertFalse(result.notCat)
    }

    func testVisualAnalysisResultSupportsNotCat() throws {
        let json = """
        {
          "headline": "No clear cat was visible",
          "confidence": "Low confidence",
          "observations": [],
          "interpretation": "The photo does not show enough of a cat to read body language.",
          "recommendedAction": "Try a clearer photo where the cat is fully visible.",
          "limitations": ["No clear cat detected"],
          "notCat": true
        }
        """

        let result = try JSONDecoder().decode(VisualAnalysisResult.self, from: Data(json.utf8))

        XCTAssertTrue(result.notCat)
        XCTAssertEqual(result.limitations, ["No clear cat detected"])
    }

    func testLocalVisualAnalysisRecognizesCatConservatively() {
        let result = VisualAnalysisService.makeAnalysis(
            from: [
                VisualAnimalDetection(
                    identifier: "Cat",
                    confidence: 0.82,
                    boundingBox: CGRect(x: 0.2, y: 0.1, width: 0.6, height: 0.7)
                )
            ],
            catName: "Mimi"
        )

        XCTAssertFalse(result.notCat)
        XCTAssertEqual(result.headline, "Mimi is visible in this photo")
        XCTAssertEqual(result.confidence, "High confidence")
        XCTAssertEqual(result.observations.first?.value, "cat detected")
        XCTAssertTrue(result.observations.contains { $0.category == "posture" && $0.value == "not readable locally" })
        XCTAssertTrue(result.limitations.contains("No photo leaves your device for analysis."))
    }

    func testLocalVisualAnalysisReportsNotCatWhenNoCatDetected() {
        let result = VisualAnalysisService.makeAnalysis(
            from: [
                VisualAnimalDetection(
                    identifier: "Dog",
                    confidence: 0.9,
                    boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.5)
                )
            ],
            catName: "Mimi"
        )

        XCTAssertTrue(result.notCat)
        XCTAssertEqual(result.headline, "No clear cat was detected")
        XCTAssertEqual(result.confidence, "Low confidence")
        XCTAssertEqual(result.observations.first?.value, "animal detected")
    }

    func testVisualAnalysisServiceRejectsEmptyImageData() async throws {
        do {
            _ = try await VisualAnalysisService().analyze(imageData: Data(), catName: "Mimi")
            XCTFail("Expected empty image data to throw")
        } catch let error as VisualAnalysisService.ServiceError {
            XCTAssertEqual(error, .invalidImage)
        }
    }

    func testGeneratedInterpretationsUseShortPlainCatPhrases() {
        let analyses = [
            AudioSignalAnalysis(
                duration: 2.5,
                powerSamples: Array(repeating: -10, count: 32),
                normalizedSamples: Array(repeating: 0.82, count: 32)
            ),
            AudioSignalAnalysis(
                duration: 1.2,
                powerSamples: [-55, -18, -36, -37, -55, -45, -44, -45],
                normalizedSamples: [0.10, 0.72, 0.34, 0.32, 0.10, 0.22, 0.21, 0.22]
            ),
            AudioSignalAnalysis(
                duration: 5.1,
                powerSamples: Array(repeating: -46, count: 60),
                normalizedSamples: Array(repeating: 0.22, count: 60)
            ),
            AudioSignalAnalysis(
                duration: 2.7,
                powerSamples: [-55, -18, -18, -55, -55, -55, -17, -18, -55, -55, -55, -16, -17, -55],
                normalizedSamples: [0.10, 0.70, 0.72, 0.10, 0.10, 0.10, 0.74, 0.71, 0.10, 0.10, 0.10, 0.78, 0.74, 0.10]
            ),
            AudioSignalAnalysis(
                duration: 2.4,
                powerSamples: Array(repeating: -42, count: 30),
                normalizedSamples: Array(repeating: 0.30, count: 30)
            )
        ]
        let technicalFragments = [
            "pattern",
            "signal",
            "peak",
            "pitch",
            "quality",
            "routine possible",
            "probable",
            "interpretation"
        ]

        for analysis in analyses {
            let message = CatTranslationEngine.makeMessage(
                from: capture(duration: 2.5, analysis: analysis),
                catName: "Mimi",
                history: [],
                now: dateAt(hour: 15),
                profile: profile()
            )
            let visibleCopy = message.translationText.lowercased()

            XCTAssertLessThanOrEqual(
                message.translationText.split(separator: " ").count,
                6,
                "Visible phrase should stay short: \(message.translationText)"
            )

            for fragment in technicalFragments {
                XCTAssertFalse(visibleCopy.contains(fragment), "Found technical fragment '\(fragment)' in: \(visibleCopy)")
            }
        }
    }

    private func capture(duration: TimeInterval, analysis: AudioSignalAnalysis) -> RecordedAudioCapture {
        RecordedAudioCapture(
            audioURL: URL(fileURLWithPath: "/tmp/test-\(UUID().uuidString).m4a"),
            duration: duration,
            analysis: analysis
        )
    }

    private func profile(
        ageYears: Int = 0,
        translationTone: String = "warm",
        listeningSensitivity: String = "balanced"
    ) -> CatTranslationProfile {
        CatTranslationProfile(
            ageYears: ageYears,
            translationTone: translationTone,
            isDailyRecapEnabled: true,
            dailyRecapTime: "9:00",
            listeningSensitivity: listeningSensitivity
        )
    }

    private func dateAt(hour: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = 2026
        components.month = 6
        components.day = 20
        components.hour = hour
        components.minute = 0
        components.second = 0
        return components.date ?? Date()
    }

    private func sampleVisualAnalysis() -> VisualAnalysisResult {
        VisualAnalysisResult(
            headline: "Tail is raised and ears look neutral",
            confidence: "Medium confidence",
            observations: [
                VisualObservation(category: "tail", value: "raised", note: "The tail appears upright in the photo."),
                VisualObservation(category: "ears", value: "neutral", note: "The ears do not look pinned back.")
            ],
            interpretation: "The visible signals fit an alert but comfortable moment.",
            recommendedAction: "Keep the interaction calm and let the cat choose distance.",
            limitations: ["The face is partly turned away."],
            notCat: false
        )
    }

    private var sampleVisualAnalysisJSON: String {
        """
        {
          "headline": "Tail is raised and ears look neutral",
          "confidence": "Medium confidence",
          "observations": [
            {
              "category": "tail",
              "value": "raised",
              "note": "The tail appears upright in the photo."
            },
            {
              "category": "ears",
              "value": "neutral",
              "note": "The ears do not look pinned back."
            }
          ],
          "interpretation": "The visible signals fit an alert but comfortable moment.",
          "recommendedAction": "Keep the interaction calm and let the cat choose distance.",
          "limitations": ["The face is partly turned away."],
          "notCat": false
        }
        """
    }
}
