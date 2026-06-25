import AVFoundation
import SwiftUI

struct SoundsView: View {
    @Environment(MonetizationService.self) private var monetizationService
    @State private var selectedCategory: SoundCategory = .all
    @State private var playingSound: String?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackResetTask: Task<Void, Never>?

    private let categories = SoundCategory.allCases
    private let sounds = CatSound.samples

    private var filteredSounds: [CatSound] {
        selectedCategory == .all ? sounds : sounds.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            MimiBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top, spacing: 8) {
                        PageHeading(
                            eyebrow: L10n.text("Sound library"),
                            title: L10n.text("Speak a little\nmore cat."),
                            subtitle: L10n.text("Compare common signal patterns with real-world context.")
                        )

                        SignalCompanionView(state: .ready, size: 104, assetName: "Sounds cat")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        GlassEffectContainer(spacing: 10) {
                            HStack(spacing: 10) {
                                ForEach(categories, id: \.self) { category in
                                    FilterChip(title: category.localizedTitle, isSelected: selectedCategory == category) {
                                        if category != selectedCategory {
                                            stopPlayback()
                                        }
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 12) {
                        ForEach(filteredSounds) { sound in
                            SoundCard(sound: sound, isPlaying: playingSound == sound.id) {
                                togglePlayback(of: sound)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                }
                .padding(.top, 18)
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private func togglePlayback(of sound: CatSound) {
        if playingSound == sound.id {
            stopPlayback()
            return
        }

        stopPlayback()

        guard let data = NSDataAsset(name: sound.assetName)?.data else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            guard player.play() else { return }

            audioPlayer = player
            playingSound = sound.id

            Task {
                if await monetizationService.record(.soundPlayed) {
                    stopPlayback()
                }
            }

            playbackResetTask = Task {
                let nanoseconds = UInt64(max(player.duration, 0.35) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard playingSound == sound.id else { return }
                    playingSound = nil
                    audioPlayer = nil
                }
            }
        } catch {
            stopPlayback()
        }
    }

    private func stopPlayback() {
        playbackResetTask?.cancel()
        playbackResetTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playingSound = nil
    }
}

private struct SoundCard: View {
    let sound: CatSound
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(sound.tint.opacity(0.14))
                    Text(sound.emoji).font(.system(size: 27))
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.title)
                        .font(.mimi(size: 17, weight: .heavy))
                        .foregroundStyle(MimiTheme.onSurface)

                    Text(sound.meaning)
                        .font(.mimi(size: 12, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                }

                Spacer()

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .frame(width: 42, height: 42)
                    .background(MimiTheme.primary, in: .circle)
                    .shadow(color: MimiTheme.shadowTint.opacity(0.58), radius: 12, x: 6, y: 7)
            }
            .padding(16)
            .softCard(cornerRadius: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isPlaying
                ? L10n.text("Pause %@", sound.title)
                : L10n.text("Play %@", sound.title)
        )
    }
}

private struct CatSound: Identifiable {
    var id: String { assetName }

    let assetName: String
    let category: SoundCategory
    let title: String
    let meaning: String
    let emoji: String
    let tint: Color

    static let samples = [
        CatSound(
            assetName: "freesound_community-cat-89108",
            category: .meows,
            title: L10n.text("Classic meow"),
            meaning: L10n.text("A general call whose meaning depends on location, timing, repetition, and body language."),
            emoji: "〰️",
            tint: MimiTheme.primary
        ),
        CatSound(
            assetName: "u_6ekfl947a2-cat-meow-297927",
            category: .meows,
            title: L10n.text("Short meow"),
            meaning: L10n.text("A brief contact call that may be a greeting, check-in, or simple request."),
            emoji: "♪",
            tint: MimiTheme.success
        ),
        CatSound(
            assetName: "mixkit-cartoon-little-cat-meow-91",
            category: .meows,
            title: L10n.text("Little cat meow"),
            meaning: L10n.text("A small, high-pitched call often used to get attention or maintain contact."),
            emoji: "♫",
            tint: MimiTheme.tertiary
        ),
        CatSound(
            assetName: "mixkit-sweet-kitty-meow-93",
            category: .meows,
            title: L10n.text("Sweet meow"),
            meaning: L10n.text("A soft social call that can accompany greeting, proximity, or friendly attention."),
            emoji: "♡",
            tint: MimiTheme.primaryInk
        ),
        CatSound(
            assetName: "mixkit-big-wild-cat-long-purr-96",
            category: .purring,
            title: L10n.text("Long purr"),
            meaning: L10n.text("Often linked to comfort, but purring can also be self-soothing; always read the posture too."),
            emoji: "≈",
            tint: MimiTheme.success
        ),
        CatSound(
            assetName: "mixkit-domestic-cat-hungry-meow-45",
            category: .hunger,
            title: L10n.text("Hungry meow"),
            meaning: L10n.text("A food-related request, especially near a bowl or around the cat's usual mealtime."),
            emoji: "◌",
            tint: MimiTheme.tertiary
        ),
        CatSound(
            assetName: "mixkit-little-cat-pain-meow-87",
            category: .pain,
            title: L10n.text("Pain meow"),
            meaning: L10n.text("A strained or unusual cry can signal distress. Check for other changes and contact a veterinarian if concerned."),
            emoji: "+",
            tint: MimiTheme.error
        ),
        CatSound(
            assetName: "freesound_community-angry-cat-41822",
            category: .anger,
            title: L10n.text("Angry warning"),
            meaning: L10n.text("A defensive warning asking for more distance. Stop approaching and leave an easy exit."),
            emoji: "!",
            tint: MimiTheme.error
        ),
        CatSound(
            assetName: "freesound_community-angry-cat-70623",
            category: .anger,
            title: L10n.text("Prolonged angry call"),
            meaning: L10n.text("A sustained conflict signal. Reduce pressure, separate triggers, and avoid handling the cat."),
            emoji: "!!",
            tint: MimiTheme.error
        ),
        CatSound(
            assetName: "freesound_community-very-angry-cat-101289",
            category: .anger,
            title: L10n.text("Intense angry warning"),
            meaning: L10n.text("High-intensity defensive vocalization. Give immediate space and do not punish the warning."),
            emoji: "⚠︎",
            tint: MimiTheme.error
        ),
        CatSound(
            assetName: "mixkit-angry-wild-cat-roar-89",
            category: .anger,
            title: L10n.text("Wild cat roar"),
            meaning: L10n.text("A forceful wild-cat threat sound included as a comparison, not a typical domestic-cat call."),
            emoji: "▲",
            tint: MimiTheme.outline
        )
    ]
}

private enum SoundCategory: String, CaseIterable, Identifiable {
    case all
    case meows
    case purring
    case hunger
    case pain
    case anger

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .all:
            L10n.text("All")
        case .meows:
            L10n.text("Meows")
        case .purring:
            L10n.text("Purring")
        case .hunger:
            L10n.text("Hunger")
        case .pain:
            L10n.text("Pain")
        case .anger:
            L10n.text("Anger")
        }
    }
}
