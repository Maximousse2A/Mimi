import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

private let isPhotoAnalysisEnabled = false

struct HomeView: View {
    @Environment(ConversationStore.self) private var conversationStore
    @Environment(MonetizationService.self) private var monetizationService
    @AppStorage("catName") private var catName = ""
    @AppStorage("catProfileAssetName") private var catProfileAssetName = "Profile Cat 1"
    @State private var recorder = AudioRecorderService()
    @State private var activeSheet: HomeSheet?
    @State private var isPressingRecord = false
    @State private var recordingTask: Task<Void, Never>?
    @State private var statusMessage: String?
    @State private var isPhotoOptionsPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedCameraImage: UIImage?
    @State private var isAnalyzingPhoto = false
    private let visualAnalysisService = VisualAnalysisService()

    var body: some View {
        ZStack {
            MimiBackground()

            VStack(spacing: 0) {
                header
                conversationIntro
                conversationThread
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            recorderDock
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .history:
                HistoryView()
            case .profile:
                CatProfileView()
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraCaptureView(capturedImage: $capturedCameraImage)
                .ignoresSafeArea()
        }
        .confirmationDialog(
            L10n.text("Analyze a photo"),
            isPresented: $isPhotoOptionsPresented,
            titleVisibility: .visible
        ) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(L10n.text("Take Photo")) {
                    isCameraPresented = true
                }
            }

            Button(L10n.text("Choose Photo")) {
                isPhotoPickerPresented = true
            }

            Button(L10n.text("Cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("Use a clear photo where the cat is easy to see."))
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            analyzePhotoPickerItem(item)
        }
        .onChange(of: capturedCameraImage != nil) { _, hasImage in
            guard hasImage, let capturedCameraImage else { return }
            self.capturedCameraImage = nil

            Task {
                await analyzePhoto(capturedCameraImage)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            recorder.refreshPermissionState()
            statusMessage = nil
        }
        .onAppear {
            AnalyticsService.trackPageViewed("home")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                activeSheet = .profile
            } label: {
                HStack(spacing: 12) {
                    CatProfileAvatar(assetName: catProfileAssetName, size: 44)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayCatName)
                            .font(.mimi(size: 20, weight: .heavy))
                            .foregroundStyle(MimiTheme.onSurface)
                        Text(L10n.text("Mimi signal interpreter"))
                            .font(.mimi(size: 11, weight: .bold))
                            .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("Open %@'s profile", displayCatName))

            Spacer()

            headerActions
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var headerActions: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                historyButton
                    .buttonStyle(.glass)

                profileButton
                    .buttonStyle(.glass)
            }
        }
    }

    private var historyButton: some View {
        Button {
            activeSheet = .history
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MimiTheme.onSurface)
                .frame(width: 42, height: 42)
        }
        .accessibilityLabel(L10n.text("Open %@'s moments", displayCatName))
    }

    private var profileButton: some View {
        Button {
            activeSheet = .profile
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MimiTheme.onSurface)
                .frame(width: 42, height: 42)
        }
        .accessibilityLabel(L10n.text("Open %@'s profile", displayCatName))
    }

    private var conversationIntro: some View {
        VStack(spacing: 5) {
            Text(recorder.isRecording ? L10n.text("Recording real sound") : L10n.text("Signal reading"))
                .font(.mimi(size: 10, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .textCase(.uppercase)
                .tracking(1.7)

            Text(L10n.text("%@'s sound notes", displayCatName))
                .font(.mimi(size: 23, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(introStatus)
                .font(.mimi(size: 12, weight: .semibold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: recorder.isRecording)
    }

    private var conversationThread: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    if conversationStore.messages.isEmpty {
                        EmptyConversationView(catName: displayCatName, assetName: catProfileAssetName)
                            .padding(.top, 14)
                    } else {
                        ForEach(conversationStore.messages) { message in
                            CatConversationBubble(
                                message: message,
                                audioURL: message.kind == .audio ? conversationStore.audioURL(for: message) : nil,
                                photoURL: conversationStore.photoURL(for: message),
                                catName: displayCatName,
                                assetName: catProfileAssetName
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
            .onChange(of: conversationStore.messages.count) { _, _ in
                guard let lastID = conversationStore.messages.last?.id else { return }

                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
            .onAppear {
                guard let lastID = conversationStore.messages.last?.id else { return }

                DispatchQueue.main.async {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private var recorderDock: some View {
        HStack(spacing: 12) {
            if recorder.permissionState == .denied {
                Button {
                    openSettings()
                } label: {
                    Label(L10n.text("Open microphone settings"), systemImage: "mic.slash.fill")
                        .font(.mimi(size: 13, weight: .heavy))
                        .foregroundStyle(MimiTheme.primaryInk)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            } else {
                recorderStatusChip

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    if isPhotoAnalysisEnabled {
                        Button {
                            presentPhotoOptions()
                        } label: {
                            PhotoAnalyzeButton(isAnalyzing: isAnalyzingPhoto)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPhotoButtonDisabled)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(L10n.text("Analyze a photo of %@", displayCatName))
                        .accessibilityHint(L10n.text("Take or choose a photo for real visual analysis"))
                    }

                    CompactHoldToRecordButton(
                        isRecording: recorder.isRecording,
                        elapsedTime: recorder.elapsedTime,
                        power: recorder.currentPower
                    )
                    .gesture(recordingGesture)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(recorder.isRecording ? L10n.text("Recording cat %@", displayCatName) : L10n.text("Hold to record %@", displayCatName))
                    .accessibilityHint(L10n.text("Recording lasts only while your finger stays down"))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: 340, minHeight: 72)
        .glassEffect(.regular.tint(MimiTheme.surfaceContainerLowest.opacity(0.96)), in: .capsule)
        .shadow(color: MimiTheme.shadowTint.opacity(0.46), radius: 24, y: 14)
        .padding(.horizontal, 18)
        .padding(.bottom, 6)
    }

    private var displayCatName: String {
        let trimmedName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? L10n.text("your cat") : trimmedName
    }

    private var introStatus: String {
        if isPhotoAnalysisEnabled, isAnalyzingPhoto {
            return L10n.text("Checking the photo on device.")
        }

        if recorder.isRecording {
            return L10n.text("Hold steady. Mimi is saving every second.")
        }

        if conversationStore.messages.isEmpty {
            return L10n.text("Hold the button while your cat talks.")
        }

        return L10n.text("Tap any sound bubble to replay the moment.")
    }

    private var recorderStatusChip: some View {
        HStack(spacing: 8) {
            if recorder.isRecording {
                RecordingWaveBars(power: recorder.currentPower, tint: MimiTheme.error)
                    .frame(width: 28, height: 18)
            } else {
                Circle()
                    .fill(MimiTheme.success)
                    .frame(width: 8, height: 8)
                    .shadow(color: MimiTheme.success, radius: 5)
            }

            Text(recorderStatusText)
                .font(.mimi(size: 12, weight: .bold))
                .foregroundStyle(MimiTheme.onSurface.opacity(0.78))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recorderStatusText: String {
        if isPhotoAnalysisEnabled, isAnalyzingPhoto {
            return L10n.text("Analyzing photo...")
        }

        if recorder.isRecording {
            return L10n.text("Recording %@", formatDuration(recorder.elapsedTime))
        }

        if let statusMessage {
            return statusMessage
        }

        switch recorder.permissionState {
        case .denied:
            return L10n.text("Microphone access is off")
        case .unknown:
            return L10n.text("Hold to allow microphone access")
        case .granted:
            return conversationStore.messages.isEmpty ? L10n.text("%@ is ready to record", displayCatName) : L10n.text("Ready for another sound")
        }
    }

    private var isPhotoButtonDisabled: Bool {
        isAnalyzingPhoto || recorder.isRecording
    }

    private var recordingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                beginRecordingPress()
            }
            .onEnded { _ in
                endRecordingPress()
            }
    }

    private func beginRecordingPress() {
        guard !isPressingRecord else { return }

        isPressingRecord = true
        statusMessage = nil
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        recordingTask = Task {
            do {
                try await recorder.ensurePermission()
                try Task.checkCancellation()

                guard isPressingRecord else { return }
                try recorder.startRecording(in: conversationStore.recordingsDirectory)
            } catch is CancellationError {
                return
            } catch {
                isPressingRecord = false
                statusMessage = error.localizedDescription
            }
        }
    }

    private func endRecordingPress() {
        guard isPressingRecord else { return }

        isPressingRecord = false
        recordingTask?.cancel()
        recordingTask = nil

        guard recorder.isRecording else { return }

        do {
            let capture = try recorder.stopRecording()
            guard capture.duration >= 2.0 else {
                try? FileManager.default.removeItem(at: capture.audioURL)
                statusMessage = L10n.text("Record at least 2 seconds so Mimi has enough to analyze.")
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }

            _ = conversationStore.addRecording(capture, catName: displayCatName)
            statusMessage = L10n.text("%@'s sound was analyzed", displayCatName)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Task {
                await monetizationService.record(.translationCompleted)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func presentPhotoOptions() {
        guard isPhotoAnalysisEnabled else { return }
        guard !isPhotoButtonDisabled else { return }

        AnalyticsService.trackButtonClicked("analyze_photo", pageName: "home")

        statusMessage = nil
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        isPhotoOptionsPresented = true
    }

    private func analyzePhotoPickerItem(_ item: PhotosPickerItem) {
        guard isPhotoAnalysisEnabled else { return }
        selectedPhotoItem = nil

        Task { @MainActor in
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw VisualAnalysisService.ServiceError.invalidImage
                }

                await analyzePhoto(image)
            } catch let error as LocalizedError {
                statusMessage = error.errorDescription ?? L10n.text("Photo analysis unavailable.")
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } catch {
                statusMessage = L10n.text("Photo analysis unavailable.")
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    @MainActor
    private func analyzePhoto(_ image: UIImage) async {
        guard isPhotoAnalysisEnabled else { return }
        guard !isAnalyzingPhoto else { return }

        guard let imageData = PhotoImageProcessor.jpegData(from: image) else {
            statusMessage = VisualAnalysisService.ServiceError.invalidImage.errorDescription
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        isAnalyzingPhoto = true
        statusMessage = L10n.text("Analyzing photo...")

        do {
            let analysis = try await visualAnalysisService.analyze(imageData: imageData, catName: displayCatName)
            _ = try conversationStore.addPhoto(imageData: imageData, analysis: analysis, catName: displayCatName)
            statusMessage = analysis.notCat ? L10n.text("Photo checked, but no clear cat was confirmed.") : L10n.text("%@'s photo was analyzed", displayCatName)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Task {
                await monetizationService.record(.translationCompleted)
            }
        } catch let error as LocalizedError {
            statusMessage = error.errorDescription ?? L10n.text("Photo analysis unavailable.")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } catch {
            statusMessage = L10n.text("Photo analysis unavailable.")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        isAnalyzingPhoto = false
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

private enum HomeSheet: String, Identifiable {
    case history
    case profile

    var id: String { rawValue }
}

private struct EmptyConversationView: View {
    let catName: String
    let assetName: String

    var body: some View {
        VStack(spacing: 15) {
            CatProfileAvatar(assetName: assetName, size: 150)

            VStack(spacing: 7) {
                Text(L10n.text("No recordings yet"))
                    .font(.mimi(size: 19, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)

                Text(L10n.text("Hold the button below while %@ vocalizes. The sound, notes, and interpretation will appear here.", catName))
                    .font(.mimi(size: 12, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 18)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .softCard(cornerRadius: 30)
    }
}

private struct CatConversationBubble: View {
    let message: CatConversationMessage
    let audioURL: URL?
    let photoURL: URL?
    let catName: String
    let assetName: String

    @State private var isShowingAudioContext = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 9) {
            CatProfileAvatar(assetName: assetName, size: 34)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Text(catName)
                        .font(.mimi(size: 11, weight: .heavy))
                        .foregroundStyle(MimiTheme.primaryInk)

                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.mimi(size: 10, weight: .semibold))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.70))
                }

                messageContent

                messageFooter
            }
            .padding(15)
            .frame(maxWidth: 314, alignment: .leading)
            .background(MimiTheme.surfaceContainerLowest, in: .rect(cornerRadius: 22))
            .overlay(alignment: .bottomLeading) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 11,
                    topTrailingRadius: 11,
                    style: .continuous
                )
                .fill(MimiTheme.surfaceContainerLowest)
                .frame(width: 18, height: 18)
                .offset(x: -5, y: -2)
            }
            .shadow(color: MimiTheme.shadowTint.opacity(0.35), radius: 16, y: 8)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        switch message.kind {
        case .audio:
            audioContent
        case .photo:
            photoContent
        }
    }

    private var audioContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            if let audioURL {
                MessageAudioPlayer(
                    audioURL: audioURL,
                    duration: message.duration,
                    levels: message.waveformLevels
                )
            }

            Text(audioPrimaryText)
                .font(.mimi(size: 16, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if hasAudioContext {
                audioContextDisclosure
            }
        }
    }

    private var hasAudioContext: Bool {
        !message.soundSummary.isEmpty || !message.interpretationDetail.isEmpty || !message.evidenceNotes.isEmpty
    }

    private var audioPrimaryText: String {
        let legacyPairs = [
            ("Food routine possible", "I might be hungry."),
            ("Attention request probable", "I want your attention."),
            ("Play invitation possible", "I want to play."),
            ("Calm contact likely", "I'm happy you're here."),
            ("Environmental check possible", "Something caught my attention."),
            ("Low-intensity check-in", "I'm checking in."),
            ("Night call possible", "I'm calling in the quiet."),
            ("Morning routine possible", "Is it breakfast time?"),
            ("Evening routine possible", "Is it dinner or play time?"),
            ("Repeated signal likely", "I'm saying that again.")
        ]

        for (legacyKey, replacementKey) in legacyPairs where message.translationText == legacyKey || message.translationText == L10n.text(legacyKey) {
            return L10n.text(replacementKey)
        }

        return message.translationText
    }

    private var audioContextDisclosure: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isShowingAudioContext.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isShowingAudioContext ? L10n.text("Hide context") : L10n.text("Show context"))
                        .font(.mimi(size: 10.5, weight: .heavy))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .heavy))
                        .rotationEffect(.degrees(isShowingAudioContext ? 90 : 0))
                }
                .foregroundStyle(MimiTheme.primaryInk)
                .padding(.vertical, 4)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isShowingAudioContext ? L10n.text("Hide context") : L10n.text("Show context"))

            if isShowingAudioContext {
                audioContextDetails
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var audioContextDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            if !message.soundSummary.isEmpty {
                Label(message.soundSummary, systemImage: "waveform")
                    .font(.mimi(size: 10.5, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))
            }

            if !message.confidence.isEmpty {
                Label(message.confidence, systemImage: moodIcon(for: message.detectedMood))
                    .font(.mimi(size: 10.5, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))
            }

            if !message.interpretationDetail.isEmpty {
                Text(message.interpretationDetail)
                    .font(.mimi(size: 12, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !message.evidenceNotes.isEmpty {
                evidenceSection(title: L10n.text("Audio clues"), notes: Array(message.evidenceNotes.prefix(5)))
            }
        }
        .padding(.top, 1)
    }

    private var photoContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = photoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 5) {
                Label(message.soundSummary, systemImage: "camera.fill")
                    .font(.mimi(size: 10.5, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))

                Text(message.translationText)
                    .font(.mimi(size: 15, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !message.interpretationDetail.isEmpty {
                    Text(message.interpretationDetail)
                        .font(.mimi(size: 12, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let visualAnalysis = message.visualAnalysis {
                if !visualAnalysis.observations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("Visual clues"))
                            .font(.mimi(size: 10, weight: .heavy))
                            .foregroundStyle(MimiTheme.primaryInk)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        ForEach(visualAnalysis.observations.prefix(5)) { observation in
                            VStack(alignment: .leading, spacing: 1) {
                                Label(L10n.text("%@: %@", observation.category, observation.value), systemImage: "checkmark.circle.fill")
                                    .font(.mimi(size: 10.5, weight: .semibold))
                                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.88))

                                if !observation.note.isEmpty {
                                    Text(observation.note)
                                        .font(.mimi(size: 10.5, weight: .medium))
                                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.72))
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }

                if !visualAnalysis.recommendedAction.isEmpty {
                    Label(visualAnalysis.recommendedAction, systemImage: "hand.raised.fill")
                        .font(.mimi(size: 10.8, weight: .bold))
                        .foregroundStyle(MimiTheme.primaryInk)
                }

                if !visualAnalysis.limitations.isEmpty {
                    evidenceSection(title: L10n.text("Limits"), notes: Array(visualAnalysis.limitations.prefix(3)))
                }
            }
        }
    }

    private var messageFooter: some View {
        HStack(spacing: 7) {
            switch message.kind {
            case .audio:
                Label(CatMood.localizedName(for: message.detectedMood), systemImage: moodIcon(for: message.detectedMood))
            case .photo:
                Label(message.confidence, systemImage: moodIcon(for: message.detectedMood))
                Text(L10n.text("Visual signals"))
            }
        }
        .font(.mimi(size: 10, weight: .heavy))
        .foregroundStyle(MimiTheme.primaryInk)
    }

    private var photoImage: UIImage? {
        guard let photoURL else { return nil }
        return UIImage(contentsOfFile: photoURL.path)
    }

    private func evidenceSection(title: String, notes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.mimi(size: 10, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .textCase(.uppercase)
                .tracking(0.8)

            ForEach(notes, id: \.self) { note in
                Label(note, systemImage: "checkmark.circle.fill")
                    .font(.mimi(size: 10.5, weight: .semibold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.86))
            }
        }
    }

    private func moodIcon(for mood: String) -> String {
        switch mood {
        case "Attention": "exclamationmark.bubble.fill"
        case "Playful": "sparkles"
        case "Hungry": "fork.knife"
        case "Affection": "heart.fill"
        case "Curious": "magnifyingglass"
        case "Visual": "camera.fill"
        default: "checkmark.seal.fill"
        }
    }
}

private struct PhotoAnalyzeButton: View {
    let isAnalyzing: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(MimiTheme.primary.opacity(isAnalyzing ? 0.24 : 0.11), lineWidth: 2)
                .frame(width: isAnalyzing ? 65 : 60, height: isAnalyzing ? 65 : 60)
                .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isAnalyzing)

            Circle()
                .fill(MimiTheme.surfaceContainerLowest)
                .frame(width: 54, height: 54)
                .overlay {
                    Circle()
                        .stroke(MimiTheme.primary.opacity(0.45), lineWidth: 1.2)
                }
                .shadow(color: MimiTheme.primary.opacity(0.16), radius: 10, y: 6)

            if isAnalyzing {
                ProgressView()
                    .tint(MimiTheme.primaryInk)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
            }
        }
        .frame(width: 62, height: 66)
        .contentShape(.circle)
        .opacity(isAnalyzing ? 0.82 : 1)
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.capturedImage = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private struct MessageAudioPlayer: View {
    let audioURL: URL
    let duration: TimeInterval
    let levels: [Double]

    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackResetTask: Task<Void, Never>?

    var body: some View {
        Button {
            togglePlayback()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .frame(width: 32, height: 32)
                    .background(MimiTheme.primary.opacity(0.26), in: .circle)

                AudioWaveform(levels: levels, isActive: isPlaying)

                Text(formatDuration(duration))
                    .font(.mimi(size: 12, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.78))
                    .monospacedDigit()
            }
            .padding(8)
            .background(MimiTheme.secondary.opacity(0.72), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text("Play recorded sound"))
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            playbackResetTask?.cancel()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            isPlaying = true

            playbackResetTask?.cancel()
            playbackResetTask = Task {
                let nanoseconds = UInt64(max(duration, 0.35) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)

                await MainActor.run {
                    isPlaying = false
                }
            }
        } catch {
            isPlaying = false
        }
    }
}

private struct AudioWaveform: View {
    let levels: [Double]
    let isActive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(isActive ? MimiTheme.primaryInk : MimiTheme.onSurfaceVariant.opacity(0.52))
                    .frame(width: 3, height: 8 + CGFloat(level) * 24)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
    }
}

private struct CompactHoldToRecordButton: View {
    let isRecording: Bool
    let elapsedTime: TimeInterval
    let power: Float

    private var normalizedPower: CGFloat {
        let clamped = min(max(power, -60), 0)
        return CGFloat((clamped + 60) / 60)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(MimiTheme.primary.opacity(isRecording ? 0.24 : 0.11), lineWidth: 2)
                .frame(width: 66 + normalizedPower * 16, height: 66 + normalizedPower * 16)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: normalizedPower)

            Circle()
                .fill(MimiTheme.heroGradient)
                .frame(width: 60, height: 60)
                .shadow(color: MimiTheme.primary.opacity(isRecording ? 0.48 : 0.25), radius: isRecording ? 18 : 12, y: 8)

            VStack(spacing: 2) {
                if isRecording {
                    RecordingWaveBars(power: power, tint: MimiTheme.primaryInk)
                        .frame(width: 28, height: 21)
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(MimiTheme.primaryInk)
                }

                Text(isRecording ? formatDuration(elapsedTime) : L10n.text("Hold"))
                    .font(.mimi(size: 10, weight: .heavy))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .monospacedDigit()
            }
        }
        .frame(width: 78, height: 66)
        .contentShape(.circle)
    }
}

private struct RecordingWaveBars: View {
    let power: Float
    let tint: Color

    private let barCount = 5

    private var normalizedPower: Double {
        let clamped = min(max(power, -60), 0)
        return max(0.12, Double((clamped + 60) / 60))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(tint)
                        .frame(width: 3.5, height: barHeight(for: index, time: time))
                        .shadow(color: tint.opacity(0.28), radius: 4)
                }
            }
        }
    }

    private func barHeight(for index: Int, time: TimeInterval) -> CGFloat {
        let phase = sin(time * 8.5 + Double(index) * 0.9)
        let wave = (phase + 1) / 2
        let energy = 0.34 + normalizedPower * 0.66
        let height = 6 + wave * 15 * energy
        return CGFloat(height)
    }
}

#Preview {
    HomeView()
        .environment(ConversationStore.preview)
        .environment(MonetizationService())
}

private func formatDuration(_ duration: TimeInterval) -> String {
    let totalSeconds = max(0, Int(duration.rounded()))
    return "\(totalSeconds / 60):" + String(format: "%02d", totalSeconds % 60)
}
