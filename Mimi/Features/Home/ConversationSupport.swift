import AVFoundation
import Foundation
import Observation
import UIKit
import Vision

enum ConversationMessageKind: String, Codable, Equatable, Sendable {
    case audio
    case photo
}

struct VisualAnalysisResult: Codable, Equatable, Sendable {
    let headline: String
    let confidence: String
    let observations: [VisualObservation]
    let interpretation: String
    let recommendedAction: String
    let limitations: [String]
    let notCat: Bool
}

struct VisualObservation: Identifiable, Codable, Equatable, Sendable {
    let category: String
    let value: String
    let note: String

    var id: String {
        [category, value, note].joined(separator: "|")
    }
}

struct CatConversationMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ConversationMessageKind
    let createdAt: Date
    let audioFileName: String
    let photoFileName: String
    let duration: TimeInterval
    let soundSummary: String
    let translationText: String
    let confidence: String
    let detectedMood: String
    let waveformLevels: [Double]
    let interpretationDetail: String
    let evidenceNotes: [String]
    let visualAnalysis: VisualAnalysisResult?

    init(
        id: UUID,
        kind: ConversationMessageKind = .audio,
        createdAt: Date,
        audioFileName: String = "",
        photoFileName: String = "",
        duration: TimeInterval = 0,
        soundSummary: String,
        translationText: String,
        confidence: String,
        detectedMood: String,
        waveformLevels: [Double] = [],
        interpretationDetail: String = "",
        evidenceNotes: [String] = [],
        visualAnalysis: VisualAnalysisResult? = nil
    ) {
        self.id = id
        self.kind = kind
        self.createdAt = createdAt
        self.audioFileName = audioFileName
        self.photoFileName = photoFileName
        self.duration = duration
        self.soundSummary = soundSummary
        self.translationText = translationText
        self.confidence = confidence
        self.detectedMood = detectedMood
        self.waveformLevels = waveformLevels
        self.interpretationDetail = interpretationDetail
        self.evidenceNotes = evidenceNotes
        self.visualAnalysis = visualAnalysis
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case createdAt
        case audioFileName
        case photoFileName
        case duration
        case soundSummary
        case translationText
        case confidence
        case detectedMood
        case waveformLevels
        case interpretationDetail
        case evidenceNotes
        case visualAnalysis
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        audioFileName = try container.decodeIfPresent(String.self, forKey: .audioFileName) ?? ""
        photoFileName = try container.decodeIfPresent(String.self, forKey: .photoFileName) ?? ""
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        soundSummary = try container.decode(String.self, forKey: .soundSummary)
        translationText = try container.decode(String.self, forKey: .translationText)
        confidence = try container.decode(String.self, forKey: .confidence)
        detectedMood = try container.decode(String.self, forKey: .detectedMood)
        waveformLevels = try container.decodeIfPresent([Double].self, forKey: .waveformLevels) ?? []
        interpretationDetail = try container.decodeIfPresent(String.self, forKey: .interpretationDetail) ?? ""
        evidenceNotes = try container.decodeIfPresent([String].self, forKey: .evidenceNotes) ?? []
        visualAnalysis = try container.decodeIfPresent(VisualAnalysisResult.self, forKey: .visualAnalysis)
        kind = try container.decodeIfPresent(ConversationMessageKind.self, forKey: .kind)
            ?? (visualAnalysis == nil && photoFileName.isEmpty ? .audio : .photo)
    }
}

struct RecordedAudioCapture {
    let audioURL: URL
    let duration: TimeInterval
    let analysis: AudioSignalAnalysis
}

enum PhotoImageProcessor {
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 1280, compressionQuality: CGFloat = 0.82) -> Data? {
        let targetImage = resizedImage(from: image, maxDimension: maxDimension)
        return targetImage.jpegData(compressionQuality: compressionQuality)
    }

    private static func resizedImage(from image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)

        guard longestSide > maxDimension, longestSide > 0 else {
            return image
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

struct VisualAnimalDetection: Equatable {
    let identifier: String
    let confidence: Float
    let boundingBox: CGRect
}

struct VisualAnalysisService: Sendable {
    enum ServiceError: LocalizedError, Equatable {
        case invalidImage
        case analysisFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                L10n.text("Photo analysis unavailable. Mimi could not prepare this image.")
            case .analysisFailed:
                L10n.text("Photo analysis unavailable. Mimi could not read this photo on device.")
            }
        }
    }

    func analyze(imageData: Data, catName: String) async throws -> VisualAnalysisResult {
        guard !imageData.isEmpty else {
            throw ServiceError.invalidImage
        }

        return try await Task.detached(priority: .userInitiated) {
            let detections = try Self.detectAnimals(in: imageData)
            return Self.makeAnalysis(from: detections, catName: catName)
        }.value
    }

    private static func detectAnimals(in imageData: Data) throws -> [VisualAnimalDetection] {
        do {
            let request = VNRecognizeAnimalsRequest()
            let handler = VNImageRequestHandler(data: imageData)

            try handler.perform([request])

            return request.results?.compactMap { observation in
                guard let label = observation.labels.max(by: { $0.confidence < $1.confidence }) else {
                    return nil
                }

                return VisualAnimalDetection(
                    identifier: label.identifier,
                    confidence: label.confidence,
                    boundingBox: observation.boundingBox
                )
            } ?? []
        } catch {
            throw ServiceError.analysisFailed
        }
    }

    static func makeAnalysis(from detections: [VisualAnimalDetection], catName: String) -> VisualAnalysisResult {
        let catDetections = detections
            .filter { isCatIdentifier($0.identifier) && $0.confidence >= 0.25 }
            .sorted { $0.confidence > $1.confidence }

        guard let bestCat = catDetections.first else {
            let sawOtherAnimal = detections.contains { $0.confidence >= 0.35 }
            let observations: [VisualObservation] = sawOtherAnimal ? [
                VisualObservation(
                    category: "context",
                    value: L10n.text("animal detected"),
                    note: L10n.text("Apple Vision saw an animal in this photo, but did not confirm a cat clearly enough.")
                )
            ] : []

            return VisualAnalysisResult(
                headline: L10n.text("No clear cat was detected"),
                confidence: L10n.text("Low confidence"),
                observations: observations,
                interpretation: L10n.text("Mimi could not confirm a cat in this image using free on-device analysis."),
                recommendedAction: L10n.text("Try a brighter, closer photo where the cat's full body and face are visible."),
                limitations: [
                    L10n.text("This local model can miss cats in dark, blurry, or cropped photos."),
                    L10n.text("No photo leaves your device for analysis.")
                ],
                notCat: true
            )
        }

        let catName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = catName.isEmpty ? L10n.text("A cat") : catName
        let framing = framingDescription(for: bestCat.boundingBox)

        return VisualAnalysisResult(
            headline: L10n.text("%@ is visible in this photo", subject),
            confidence: confidenceDescription(for: bestCat.confidence),
            observations: [
                VisualObservation(
                    category: "context",
                    value: L10n.text("cat detected"),
                    note: L10n.text("Apple Vision recognized a cat in the image on this device.")
                ),
                VisualObservation(
                    category: "context",
                    value: framing.value,
                    note: framing.note
                ),
                VisualObservation(
                    category: "posture",
                    value: L10n.text("not readable locally"),
                    note: L10n.text("This free on-device analysis cannot reliably evaluate tail, ears, posture, or facial expression.")
                )
            ],
            interpretation: L10n.text("The photo contains a likely cat, but Mimi is using a free local detector, so it only confirms the cat and framing rather than interpreting mood."),
            recommendedAction: L10n.text("Use the photo as a prompt to check visible clues yourself: tail, ears, posture, eyes, and context."),
            limitations: [
                L10n.text("Tail, ears, face, and posture are not interpreted by this free local model."),
                L10n.text("No photo leaves your device for analysis.")
            ],
            notCat: false
        )
    }

    private static func isCatIdentifier(_ identifier: String) -> Bool {
        identifier == VNAnimalIdentifier.cat.rawValue || identifier.lowercased() == "cat"
    }

    private static func confidenceDescription(for confidence: Float) -> String {
        switch confidence {
        case 0.75...:
            L10n.text("High confidence")
        case 0.45..<0.75:
            L10n.text("Medium confidence")
        default:
            L10n.text("Low confidence")
        }
    }

    private static func framingDescription(for boundingBox: CGRect) -> (value: String, note: String) {
        let area = boundingBox.width * boundingBox.height

        switch area {
        case 0.35...:
            return (
                L10n.text("close framing"),
                L10n.text("The cat takes up enough of the photo for a clearer visual record.")
            )
        case 0.12..<0.35:
            return (
                L10n.text("moderate framing"),
                L10n.text("The cat is visible, though a closer photo may show body-language clues more clearly.")
            )
        default:
            return (
                L10n.text("distant framing"),
                L10n.text("The cat appears small in the frame, so visible body-language clues may be limited.")
            )
        }
    }
}

struct AudioSignalAnalysis: Codable, Equatable {
    let averagePower: Float
    let peakPower: Float
    let peakCount: Int
    let silenceGapCount: Int
    let intensity: AudioIntensity
    let vocalPattern: VocalPattern
    let energyTrend: EnergyTrend
    let pitchBand: PitchBand
    let signalQuality: SignalQuality
    let interpretationConfidence: InterpretationConfidence
    let waveformLevels: [Double]

    init(
        duration: TimeInterval,
        powerSamples: [Float],
        normalizedSamples: [Double],
        audioURL: URL? = nil
    ) {
        let samples = powerSamples.filter(\.isFinite)
        let computedAveragePower = samples.isEmpty ? -60 : samples.reduce(0, +) / Float(samples.count)
        let computedPeakPower = samples.max() ?? -80
        let computedPeakCount = Self.countPeakClusters(in: samples)
        let computedSilenceGapCount = Self.countSilenceGaps(in: samples)
        let computedIntensity = Self.classify(
            duration: duration,
            averagePower: computedAveragePower,
            peakPower: computedPeakPower,
            peakCount: computedPeakCount
        )
        let computedEnergyTrend = Self.classifyEnergyTrend(normalizedSamples)
        let computedSignalQuality = Self.classifySignalQuality(
            duration: duration,
            samples: samples,
            normalizedSamples: normalizedSamples,
            averagePower: computedAveragePower,
            peakPower: computedPeakPower
        )
        let fileMetrics = audioURL.flatMap(Self.audioFileMetrics)
        let computedPitchBand = Self.classifyPitch(
            zeroCrossingRate: fileMetrics?.zeroCrossingRate,
            signalQuality: computedSignalQuality
        )
        let computedVocalPattern = Self.classifyPattern(
            duration: duration,
            peakCount: computedPeakCount,
            silenceGapCount: computedSilenceGapCount,
            intensity: computedIntensity,
            signalQuality: computedSignalQuality
        )

        averagePower = computedAveragePower
        peakPower = computedPeakPower
        peakCount = computedPeakCount
        silenceGapCount = computedSilenceGapCount
        intensity = computedIntensity
        vocalPattern = computedVocalPattern
        energyTrend = computedEnergyTrend
        pitchBand = computedPitchBand
        signalQuality = computedSignalQuality
        interpretationConfidence = Self.classifyConfidence(
            duration: duration,
            peakCount: computedPeakCount,
            vocalPattern: computedVocalPattern,
            pitchBand: computedPitchBand,
            signalQuality: computedSignalQuality
        )
        waveformLevels = Self.resample(normalizedSamples, to: 22)
    }

    private static func classify(duration: TimeInterval, averagePower: Float, peakPower: Float, peakCount: Int) -> AudioIntensity {
        if peakPower > -12 || averagePower > -22 || peakCount >= 6 {
            return .urgent
        }

        if peakPower > -20 || averagePower > -34 || peakCount >= 3 {
            return .bright
        }

        if duration > 3.0 || averagePower > -48 {
            return .steady
        }

        return .soft
    }

    private static func countPeakClusters(in samples: [Float]) -> Int {
        var count = 0
        var isInsidePeak = false

        for sample in samples {
            if sample > -20, !isInsidePeak {
                count += 1
                isInsidePeak = true
            } else if sample < -30 {
                isInsidePeak = false
            }
        }

        return count
    }

    private static func countSilenceGaps(in samples: [Float]) -> Int {
        var gaps = 0
        var quietRun = 0
        var countedCurrentRun = false

        for sample in samples {
            if sample < -52 {
                quietRun += 1
                if quietRun >= 3, !countedCurrentRun {
                    gaps += 1
                    countedCurrentRun = true
                }
            } else {
                quietRun = 0
                countedCurrentRun = false
            }
        }

        return gaps
    }

    private static func classifyPattern(
        duration: TimeInterval,
        peakCount: Int,
        silenceGapCount: Int,
        intensity: AudioIntensity,
        signalQuality: SignalQuality
    ) -> VocalPattern {
        if signalQuality == .limited || signalQuality == .quiet, peakCount == 0 {
            return .unclear
        }

        if intensity == .urgent, peakCount >= 3 {
            return .intenseCall
        }

        if silenceGapCount >= 2 || peakCount >= 3 {
            return .repeatedCall
        }

        if duration >= 4.0 {
            return .sustainedCall
        }

        if duration < 1.5 {
            return .shortCall
        }

        return .singleCall
    }

    private static func classifyEnergyTrend(_ levels: [Double]) -> EnergyTrend {
        guard levels.count >= 6 else { return .steady }

        let average = Self.average(levels)
        let firstCount = max(1, levels.count / 3)
        let lastCount = max(1, levels.count / 3)
        let firstAverage = Self.average(Array(levels.prefix(firstCount)))
        let lastAverage = Self.average(Array(levels.suffix(lastCount)))
        let peak = levels.max() ?? average

        if peak / max(average, 0.01) > 2.35 {
            return .bursty
        }

        if lastAverage - firstAverage > 0.16 {
            return .rising
        }

        if firstAverage - lastAverage > 0.16 {
            return .falling
        }

        return .steady
    }

    private static func classifySignalQuality(
        duration: TimeInterval,
        samples: [Float],
        normalizedSamples: [Double],
        averagePower: Float,
        peakPower: Float
    ) -> SignalQuality {
        guard duration >= 1.0, samples.count >= 6 else {
            return .limited
        }

        if peakPower > -3 {
            return .clipped
        }

        let activeSamples = samples.filter { $0 > -50 }.count
        let activeRatio = Double(activeSamples) / Double(max(samples.count, 1))
        let averageLevel = Self.average(normalizedSamples)

        if averagePower < -55 || averageLevel < 0.11 || activeRatio < 0.18 {
            return .quiet
        }

        return .clear
    }

    private static func classifyPitch(
        zeroCrossingRate: Double?,
        signalQuality: SignalQuality
    ) -> PitchBand {
        guard signalQuality != .limited,
              let zeroCrossingRate else {
            return .unknown
        }

        if zeroCrossingRate < 0.08 {
            return .low
        }

        if zeroCrossingRate < 0.18 {
            return .middle
        }

        return .high
    }

    private static func classifyConfidence(
        duration: TimeInterval,
        peakCount: Int,
        vocalPattern: VocalPattern,
        pitchBand: PitchBand,
        signalQuality: SignalQuality
    ) -> InterpretationConfidence {
        if signalQuality == .limited || signalQuality == .quiet || vocalPattern == .unclear {
            return .low
        }

        if signalQuality == .clear,
           pitchBand != .unknown,
           duration >= 2.4,
           peakCount >= 1 || vocalPattern == .sustainedCall {
            return .high
        }

        return .medium
    }

    private static func audioFileMetrics(from url: URL) -> AudioFileMetrics? {
        do {
            let file = try AVAudioFile(forReading: url)
            let frameCount = min(Int(file.length), 88_200)
            guard frameCount > 0,
                  let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(frameCount)
                  ) else {
                return nil
            }

            try file.read(into: buffer, frameCount: AVAudioFrameCount(frameCount))

            guard let channelData = buffer.floatChannelData,
                  Int(buffer.frameLength) > 2 else {
                return nil
            }

            let samples = channelData[0]
            let sampleCount = Int(buffer.frameLength)
            let threshold: Float = 0.012
            var previousSign: Int?
            var activeSamples = 0
            var crossings = 0

            for index in 0..<sampleCount {
                let value = samples[index]
                guard abs(value) > threshold else { continue }

                activeSamples += 1
                let sign = value >= 0 ? 1 : -1
                if let previousSign, previousSign != sign {
                    crossings += 1
                }
                previousSign = sign
            }

            guard activeSamples > 80 else { return nil }
            return AudioFileMetrics(zeroCrossingRate: Double(crossings) / Double(activeSamples))
        } catch {
            return nil
        }
    }

    private static func resample(_ levels: [Double], to count: Int) -> [Double] {
        guard !levels.isEmpty else {
            return Array(repeating: 0.18, count: count)
        }

        return (0..<count).map { index in
            let rawStart = Double(index) * Double(levels.count) / Double(count)
            let rawEnd = Double(index + 1) * Double(levels.count) / Double(count)
            let start = min(Int(rawStart.rounded(.down)), levels.count - 1)
            let end = min(max(start + 1, Int(rawEnd.rounded(.up))), levels.count)
            let peak = levels[start..<end].max() ?? 0.18
            return min(max(peak, 0.12), 1.0)
        }
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private struct AudioFileMetrics {
        let zeroCrossingRate: Double
    }
}

enum AudioIntensity: String, Codable, Equatable {
    case soft
    case steady
    case bright
    case urgent

    var summaryWord: String {
        switch self {
        case .soft: L10n.text("soft")
        case .steady: L10n.text("steady")
        case .bright: L10n.text("animated")
        case .urgent: L10n.text("urgent")
        }
    }
}

enum VocalPattern: String, Codable, Equatable {
    case shortCall
    case singleCall
    case repeatedCall
    case sustainedCall
    case intenseCall
    case unclear

    var summaryWord: String {
        switch self {
        case .shortCall: L10n.text("short call")
        case .singleCall: L10n.text("single call")
        case .repeatedCall: L10n.text("repeated call")
        case .sustainedCall: L10n.text("sustained call")
        case .intenseCall: L10n.text("intense call")
        case .unclear: L10n.text("unclear signal")
        }
    }
}

enum EnergyTrend: String, Codable, Equatable {
    case steady
    case rising
    case falling
    case bursty

    var summaryWord: String {
        switch self {
        case .steady: L10n.text("steady energy")
        case .rising: L10n.text("rising energy")
        case .falling: L10n.text("fading energy")
        case .bursty: L10n.text("bursty energy")
        }
    }
}

enum PitchBand: String, Codable, Equatable {
    case low
    case middle
    case high
    case unknown

    var summaryWord: String {
        switch self {
        case .low: L10n.text("low pitch")
        case .middle: L10n.text("mid pitch")
        case .high: L10n.text("high pitch")
        case .unknown: L10n.text("pitch unclear")
        }
    }
}

enum SignalQuality: String, Codable, Equatable {
    case clear
    case quiet
    case clipped
    case limited

    var summaryWord: String {
        switch self {
        case .clear: L10n.text("clear signal")
        case .quiet: L10n.text("quiet signal")
        case .clipped: L10n.text("peaking signal")
        case .limited: L10n.text("limited signal")
        }
    }
}

enum InterpretationConfidence: String, Codable, Equatable {
    case low
    case medium
    case high

    var localizedLabel: String {
        switch self {
        case .low: L10n.text("Low confidence")
        case .medium: L10n.text("Medium confidence")
        case .high: L10n.text("High confidence")
        }
    }
}

@MainActor
@Observable
final class ConversationStore {
    enum StorageMode {
        case persistent
        case inMemory
    }

    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let metadataURL: URL?
    let recordingsDirectory: URL
    let photosDirectory: URL

    private(set) var messages: [CatConversationMessage] = []
    private(set) var loadErrorMessage: String?

    init(storageMode: StorageMode = .persistent, fileManager: FileManager = .default) {
        self.fileManager = fileManager

        switch storageMode {
        case .persistent:
            let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            let appDirectory = supportDirectory.appendingPathComponent("Mimi", isDirectory: true)
            recordingsDirectory = appDirectory.appendingPathComponent("Recordings", isDirectory: true)
            photosDirectory = appDirectory.appendingPathComponent("Photos", isDirectory: true)
            metadataURL = appDirectory.appendingPathComponent("conversations.json")
        case .inMemory:
            let appDirectory = fileManager.temporaryDirectory.appendingPathComponent("MimiPreview", isDirectory: true)
            recordingsDirectory = appDirectory.appendingPathComponent("Recordings", isDirectory: true)
            photosDirectory = appDirectory.appendingPathComponent("Photos", isDirectory: true)
            metadataURL = nil
        }

        prepareStorage()
        load()
    }

    func addRecording(_ capture: RecordedAudioCapture, catName: String) -> CatConversationMessage {
        let message = CatTranslationEngine.makeMessage(
            from: capture,
            catName: catName,
            history: messages,
            now: Date(),
            profile: .current
        )
        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
        save()
        return message
    }

    func addPhoto(imageData: Data, analysis: VisualAnalysisResult, catName: String) throws -> CatConversationMessage {
        try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)

        let fileName = "cat-photo-\(UUID().uuidString).jpg"
        let photoURL = photosDirectory.appendingPathComponent(fileName)
        try imageData.write(to: photoURL, options: .atomic)

        let message = CatConversationMessage(
            id: UUID(),
            kind: .photo,
            createdAt: Date(),
            photoFileName: fileName,
            soundSummary: analysis.notCat ? L10n.text("Photo could not confirm a cat") : L10n.text("On-device photo check"),
            translationText: analysis.headline,
            confidence: analysis.confidence,
            detectedMood: "Visual",
            interpretationDetail: analysis.interpretation,
            evidenceNotes: analysis.observations.map { observation in
                L10n.text("%@: %@", observation.category, observation.value)
            },
            visualAnalysis: analysis
        )

        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
        save()
        return message
    }

    func audioURL(for message: CatConversationMessage) -> URL {
        recordingsDirectory.appendingPathComponent(message.audioFileName)
    }

    func photoURL(for message: CatConversationMessage) -> URL? {
        guard !message.photoFileName.isEmpty else { return nil }
        return photosDirectory.appendingPathComponent(message.photoFileName)
    }

    private func prepareStorage() {
        do {
            try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        } catch {
            loadErrorMessage = L10n.text("Could not prepare Mimi storage.")
        }
    }

    private func load() {
        guard let metadataURL, fileManager.fileExists(atPath: metadataURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            messages = try JSONDecoder().decode([CatConversationMessage].self, from: data)
                .sorted { $0.createdAt < $1.createdAt }
        } catch {
            loadErrorMessage = L10n.text("Could not load saved conversations.")
        }
    }

    private func save() {
        guard let metadataURL else { return }

        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            loadErrorMessage = L10n.text("Could not save this conversation.")
        }
    }

    static var preview: ConversationStore {
        let store = ConversationStore(storageMode: .inMemory)
        store.messages = [
            CatConversationMessage(
                id: UUID(),
                createdAt: Date().addingTimeInterval(-180),
                audioFileName: "preview-1.m4a",
                duration: 2.4,
                soundSummary: L10n.text("%.1fs %@, %@, %@", 2.4, L10n.text("repeated call"), L10n.text("animated"), L10n.text("%d louder peaks", 3)),
                translationText: L10n.text("Something caught my attention."),
                confidence: L10n.text("Medium confidence"),
                detectedMood: "Curious",
                waveformLevels: [0.18, 0.38, 0.62, 0.44, 0.72, 0.30, 0.24, 0.58, 0.82, 0.36, 0.22, 0.48, 0.66, 0.31, 0.20, 0.42, 0.57, 0.27, 0.18, 0.35, 0.51, 0.24],
                interpretationDetail: L10n.text("Pauses or a rising pattern can fit noticing a change nearby. Check what happened just before the sound."),
                evidenceNotes: [
                    L10n.text("Pattern: %@", L10n.text("repeated call")),
                    L10n.text("Energy: %@", L10n.text("bursty energy")),
                    L10n.text("Signal: %@", L10n.text("clear signal"))
                ]
            )
        ]
        return store
    }
}

@MainActor
@Observable
final class AudioRecorderService {
    enum PermissionState: Equatable {
        case unknown
        case granted
        case denied
    }

    enum RecorderError: LocalizedError {
        case permissionDenied
        case couldNotStart
        case noActiveRecording

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                L10n.text("Microphone access is off. Enable it to record your cat.")
            case .couldNotStart:
                L10n.text("Mimi could not start recording. Try again in a moment.")
            case .noActiveRecording:
                L10n.text("No active recording was found.")
            }
        }
    }

    private(set) var permissionState: PermissionState = .unknown
    private(set) var isRecording = false
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var currentPower: Float = -80

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var meterTimer: Timer?
    @ObservationIgnored private var startDate: Date?
    @ObservationIgnored private var powerSamples: [Float] = []
    @ObservationIgnored private var normalizedSamples: [Double] = []

    init() {
        refreshPermissionState()
    }

    func ensurePermission() async throws {
        refreshPermissionState()

        switch permissionState {
        case .granted:
            return
        case .denied:
            throw RecorderError.permissionDenied
        case .unknown:
            let allowed = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { isAllowed in
                    continuation.resume(returning: isAllowed)
                }
            }

            permissionState = allowed ? .granted : .denied

            if !allowed {
                throw RecorderError.permissionDenied
            }
        }
    }

    func startRecording(in recordingsDirectory: URL) throws {
        guard !isRecording else { return }

        try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)

        let fileName = "cat-\(UUID().uuidString).m4a"
        let audioURL = recordingsDirectory.appendingPathComponent(fileName)
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: audioURL, settings: settings)
        recorder.isMeteringEnabled = true

        guard recorder.record() else {
            throw RecorderError.couldNotStart
        }

        self.recorder = recorder
        isRecording = true
        elapsedTime = 0
        currentPower = -80
        startDate = Date()
        powerSamples = []
        normalizedSamples = []
        startMetering()
    }

    func stopRecording() throws -> RecordedAudioCapture {
        guard let recorder else {
            throw RecorderError.noActiveRecording
        }

        recorder.updateMeters()
        collectMeterSample(from: recorder)

        let audioURL = recorder.url
        let duration = max(recorder.currentTime, elapsedTime)
        let powerSamples = self.powerSamples
        let normalizedSamples = self.normalizedSamples

        recorder.stop()
        stopMetering()
        self.recorder = nil
        isRecording = false
        elapsedTime = duration
        startDate = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let analysis = AudioSignalAnalysis(
            duration: duration,
            powerSamples: powerSamples,
            normalizedSamples: normalizedSamples,
            audioURL: audioURL
        )

        return RecordedAudioCapture(audioURL: audioURL, duration: duration, analysis: analysis)
    }

    func refreshPermissionState() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionState = .granted
        case .denied:
            permissionState = .denied
        case .undetermined:
            permissionState = .unknown
        @unknown default:
            permissionState = .unknown
        }
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickMeter()
            }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func tickMeter() {
        guard let recorder, isRecording else { return }

        if let startDate {
            elapsedTime = Date().timeIntervalSince(startDate)
        }

        recorder.updateMeters()
        collectMeterSample(from: recorder)
    }

    private func collectMeterSample(from recorder: AVAudioRecorder) {
        let power = recorder.averagePower(forChannel: 0)
        currentPower = power
        powerSamples.append(power)
        normalizedSamples.append(Self.normalizedLevel(from: power))
    }

    private static func normalizedLevel(from decibels: Float) -> Double {
        let clamped = min(max(decibels, -60), 0)
        let normalized = (Double(clamped) + 60) / 60
        return max(0.08, pow(normalized, 1.7))
    }
}

struct CatTranslationProfile: Equatable {
    let ageYears: Int
    let translationTone: String
    let isDailyRecapEnabled: Bool
    let dailyRecapTime: String
    let listeningSensitivity: String

    static var current: CatTranslationProfile {
        let defaults = UserDefaults.standard
        return CatTranslationProfile(
            ageYears: defaults.integer(forKey: "catAgeYears"),
            translationTone: defaults.string(forKey: "catTranslationTone") ?? "warm",
            isDailyRecapEnabled: defaults.object(forKey: "catDailyRecapEnabled") as? Bool ?? true,
            dailyRecapTime: defaults.string(forKey: "catDailyRecapTime") ?? "9:00",
            listeningSensitivity: defaults.string(forKey: "catListeningSensitivity") ?? "balanced"
        )
    }
}

enum CatTranslationEngine {
    static func makeMessage(
        from capture: RecordedAudioCapture,
        catName: String,
        history: [CatConversationMessage],
        now: Date = Date(),
        profile: CatTranslationProfile = .current
    ) -> CatConversationMessage {
        let mood = mood(for: capture, profile: profile)
        let baseScenario = scenario(for: mood, capture: capture, now: now)
        let repeatedMessage = repeatedMessage(for: capture, mood: mood, history: history, now: now)
        let scenario = repeatedMessage == nil ? baseScenario : CatTranslationScenario.repeated
        let interpretation = interpretation(
            for: scenario,
            capture: capture,
            mood: mood,
            profile: profile,
            repeatedMessage: repeatedMessage,
            history: history,
            now: now
        )

        return CatConversationMessage(
            id: UUID(),
            createdAt: now,
            audioFileName: capture.audioURL.lastPathComponent,
            duration: capture.duration,
            soundSummary: soundSummary(for: capture),
            translationText: interpretation.title,
            confidence: interpretation.confidence.localizedLabel,
            detectedMood: mood.rawValue,
            waveformLevels: capture.analysis.waveformLevels,
            interpretationDetail: interpretation.detail,
            evidenceNotes: interpretation.evidenceNotes
        )
    }

    private struct InterpretationResult {
        let title: String
        let detail: String
        let evidenceNotes: [String]
        let confidence: InterpretationConfidence
    }

    private static func mood(for capture: RecordedAudioCapture, profile: CatTranslationProfile) -> CatMood {
        let analysis = capture.analysis
        let sensitivityBoost = profile.listeningSensitivity == "sensitive" ? 1 : 0
        let calmBias = profile.listeningSensitivity == "calm" ? 1 : 0
        let adjustedPeakCount = max(0, analysis.peakCount + sensitivityBoost - calmBias)
        let adjustedDuration = capture.duration + (profile.ageYears >= 10 ? 0.35 : 0)

        if analysis.signalQuality == .limited || analysis.signalQuality == .quiet {
            return .calm
        }

        if analysis.intensity == .urgent, profile.listeningSensitivity != "calm" {
            return .attention
        }

        if adjustedDuration < 1.8,
           analysis.intensity == .bright,
           analysis.pitchBand == .high || analysis.pitchBand == .unknown {
            return .playful
        }

        if analysis.vocalPattern == .sustainedCall, analysis.intensity == .soft || analysis.intensity == .steady {
            return .affection
        }

        if adjustedDuration > 1.6, adjustedPeakCount >= 3, analysis.vocalPattern == .repeatedCall {
            return .hungry
        }

        if analysis.silenceGapCount >= 2 || analysis.energyTrend == .rising || analysis.energyTrend == .bursty {
            return .curious
        }

        if analysis.vocalPattern == .singleCall, analysis.intensity == .bright {
            return analysis.pitchBand == .high ? .playful : .attention
        }

        if analysis.vocalPattern == .singleCall,
           adjustedDuration >= 2.4,
           analysis.intensity == .steady {
            return .affection
        }

        if analysis.intensity == .urgent {
            return .attention
        }

        return .calm
    }

    private static func scenario(for mood: CatMood, capture: RecordedAudioCapture, now: Date) -> CatTranslationScenario {
        let hour = Calendar.current.component(.hour, from: now)

        if mood == .attention {
            return .attention
        }

        if mood == .hungry || isMealWindow(hour: hour, capture: capture) {
            return .hungry
        }

        if hour >= 22 || hour < 5 {
            return .night
        }

        if (5..<10).contains(hour), mood == .calm || mood == .curious {
            return .morning
        }

        if (17..<22).contains(hour), mood == .calm || mood == .curious {
            return .evening
        }

        switch mood {
        case .attention:
            return .attention
        case .playful:
            return .playful
        case .hungry:
            return .hungry
        case .affection:
            return .affection
        case .curious:
            return .curious
        case .calm:
            return .calm
        }
    }

    private static func isMealWindow(hour: Int, capture: RecordedAudioCapture) -> Bool {
        let analysis = capture.analysis
        let isRoutineLike = analysis.vocalPattern == .repeatedCall || analysis.intensity == .bright || analysis.intensity == .urgent
        let isCommonMealTime = (6...9).contains(hour) || (11...13).contains(hour) || (17...20).contains(hour)
        return isCommonMealTime && capture.duration >= 2.0 && isRoutineLike
    }

    private static func repeatedMessage(
        for capture: RecordedAudioCapture,
        mood: CatMood,
        history: [CatConversationMessage],
        now: Date
    ) -> CatConversationMessage? {
        guard let lastMessage = history.last,
              !lastMessage.translationText.isEmpty,
              now.timeIntervalSince(lastMessage.createdAt) <= 90,
              isSimilar(capture: capture, mood: mood, to: lastMessage) else {
            return nil
        }

        let recentMessages = history.suffix(2)
        guard recentMessages.count == 2 else {
            return lastMessage
        }

        let bothRecentAndSimilar = recentMessages.allSatisfy { message in
            now.timeIntervalSince(message.createdAt) <= 120 && isSimilar(capture: capture, mood: mood, to: message)
        }

        return bothRecentAndSimilar ? lastMessage : nil
    }

    private static func isSimilar(
        capture: RecordedAudioCapture,
        mood: CatMood,
        to message: CatConversationMessage
    ) -> Bool {
        guard message.detectedMood == mood.rawValue else { return false }
        let durationDelta = abs(message.duration - capture.duration)
        let allowedDelta = max(0.85, capture.duration * 0.36)
        return durationDelta <= allowedDelta
    }

    private static func soundSummary(for capture: RecordedAudioCapture) -> String {
        let analysis = capture.analysis
        let peakText = analysis.peakCount == 1 ? L10n.text("1 louder peak") : L10n.text("%d louder peaks", analysis.peakCount)
        let gapText: String

        if analysis.silenceGapCount == 1 {
            gapText = L10n.text(", 1 quiet pause")
        } else if analysis.silenceGapCount > 1 {
            gapText = L10n.text(", %d quiet pauses", analysis.silenceGapCount)
        } else {
            gapText = ""
        }

        return L10n.text(
            "%.1fs %@, %@, %@",
            capture.duration,
            analysis.vocalPattern.summaryWord,
            analysis.intensity.summaryWord,
            peakText
        ) + gapText
    }

    private static func interpretation(
        for scenario: CatTranslationScenario,
        capture: RecordedAudioCapture,
        mood: CatMood,
        profile: CatTranslationProfile,
        repeatedMessage: CatConversationMessage?,
        history: [CatConversationMessage],
        now: Date
    ) -> InterpretationResult {
        let confidence = confidence(for: capture, scenario: scenario, profile: profile)
        let evidenceNotes = evidenceNotes(for: capture, mood: mood, scenario: scenario, repeatedMessage: repeatedMessage)
        let detail = detail(for: scenario, capture: capture, profile: profile, repeatedMessage: repeatedMessage)
        let title = CatTranslationCopy.localizedLine(
            for: scenario,
            capture: capture,
            history: history,
            now: now,
            profile: profile
        )

        return InterpretationResult(
            title: title,
            detail: detail,
            evidenceNotes: evidenceNotes,
            confidence: confidence
        )
    }

    private static func detail(
        for scenario: CatTranslationScenario,
        capture: RecordedAudioCapture,
        profile: CatTranslationProfile,
        repeatedMessage: CatConversationMessage?
    ) -> String {
        switch scenario {
        case .repeated:
            return L10n.text("Similar to a recent recording")
        case .night:
            return L10n.text("A sound during quiet hours can be routine, orientation, or a request for contact. Check posture and location before assuming a specific need.")
        case .morning:
            return L10n.text("Morning timing can point to routine or food, especially with repeated calls. Confirm with location and recent meals.")
        case .evening:
            return L10n.text("Evening calls often overlap with food, play, and settling routines. Use body language and location to narrow it down.")
        case .hungry:
            return L10n.text("Timing plus a repeated or stronger call can fit a food routine. Confirm with bowl location, recent meals, and usual habits.")
        case .attention:
            return L10n.text("Higher energy or clustered peaks suggest a request for attention. The exact reason still needs visual context.")
        case .playful:
            return L10n.text("A short, brighter call can fit greeting or play invitation. Look for loose posture, tail movement, and approach behavior.")
        case .affection:
            return L10n.text("A longer softer signal can fit calm contact or reassurance. Pair it with relaxed posture before reading it as comfort.")
        case .curious:
            return L10n.text("Pauses or a rising pattern can fit noticing a change nearby. Check what happened just before the sound.")
        case .calm:
            return lowSignalDetail(for: capture, profile: profile)
        }
    }

    private static func lowSignalDetail(for capture: RecordedAudioCapture, profile: CatTranslationProfile) -> String {
        if capture.analysis.signalQuality == .quiet || capture.analysis.signalQuality == .limited {
            return L10n.text("The signal is quiet or limited, so this should be treated as uncertain. A clearer recording would improve the read.")
        }

        if profile.translationTone == "direct" {
            return L10n.text("The signal is low intensity and does not point strongly to one need.")
        }

        return L10n.text("The signal is low intensity and does not point strongly to one need. Context will matter more than the sound alone.")
    }

    private static func confidence(
        for capture: RecordedAudioCapture,
        scenario: CatTranslationScenario,
        profile: CatTranslationProfile
    ) -> InterpretationConfidence {
        if scenario == .repeated, capture.analysis.interpretationConfidence != .low {
            return .medium
        }

        if profile.listeningSensitivity == "sensitive", capture.analysis.interpretationConfidence == .high {
            return .medium
        }

        if profile.listeningSensitivity == "calm", capture.analysis.signalQuality == .clear, capture.analysis.interpretationConfidence == .low {
            return .medium
        }

        return capture.analysis.interpretationConfidence
    }

    private static func evidenceNotes(
        for capture: RecordedAudioCapture,
        mood: CatMood,
        scenario: CatTranslationScenario,
        repeatedMessage: CatConversationMessage?
    ) -> [String] {
        let analysis = capture.analysis
        var notes = [
            L10n.text("Pattern: %@", analysis.vocalPattern.summaryWord),
            L10n.text("Energy: %@", analysis.energyTrend.summaryWord),
            L10n.text("Signal: %@", analysis.signalQuality.summaryWord)
        ]

        if analysis.pitchBand != .unknown {
            notes.append(L10n.text("Approximate pitch: %@", analysis.pitchBand.summaryWord))
        }

        if analysis.peakCount == 1 {
            notes.append(L10n.text("1 louder peak detected"))
        } else if analysis.peakCount > 1 {
            notes.append(L10n.text("%d louder peaks detected", analysis.peakCount))
        }

        if analysis.silenceGapCount == 1 {
            notes.append(L10n.text("1 quiet pause detected"))
        } else if analysis.silenceGapCount > 1 {
            notes.append(L10n.text("%d quiet pauses detected", analysis.silenceGapCount))
        }

        if scenario == .repeated, repeatedMessage != nil {
            notes.insert(L10n.text("Similar to a recent recording"), at: 0)
        }

        if scenario == .hungry || scenario == .morning || scenario == .evening {
            notes.append(L10n.text("Time of day may influence this read"))
        }

        if mood == .calm, analysis.signalQuality != .clear {
            notes.append(L10n.text("Low signal quality keeps this uncertain"))
        }

        return notes
    }
}

enum CatMood: String {
    case attention = "Attention"
    case playful = "Playful"
    case hungry = "Hungry"
    case affection = "Affection"
    case curious = "Curious"
    case calm = "Calm"
}

extension CatMood {
    static func localizedName(for rawValue: String) -> String {
        CatMood(rawValue: rawValue)?.localizedName ?? rawValue
    }

    var localizedName: String {
        L10n.text(rawValue)
    }
}
