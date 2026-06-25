import RevenueCat
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("catName") private var catName = ""
    @AppStorage("catProfileAssetName") private var catProfileAssetName = "Profile Cat 1"
    @AppStorage("hasRequestedOnboardingReview") private var hasRequestedOnboardingReview = false
    @Environment(\.requestReview) private var requestReview
    @State private var step: OnboardingStep = .welcome
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            MimiBackground()

            if isShowingSplash {
                OnboardingSplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack(spacing: 0) {
                    OnboardingHeader(step: step, goBack: goBack, close: onComplete)

                    Group {
                        switch step {
                        case .welcome:
                            storyPage(
                                assetName: "Onboarding Welcome Cat",
                                artPrompt: L10n.text("Cat waving hello"),
                                artSymbol: "pawprint.fill",
                                eyebrow: L10n.text("Welcome to Mimi"),
                                title: L10n.text("Your cat has a lot to say."),
                                subtitle: L10n.text("Record sounds, compare signals, and understand the context around them."),
                                features: []
                            )
                        case .name:
                            CatNamePage(catName: $catName, action: finishNameStep)
                        case .profile:
                            CatProfileSelectionPage(
                                catName: displayCatName,
                                selection: $catProfileAssetName,
                                action: advance
                            )
                        case .translate:
                            storyPage(
                                assetName: "Onboarding Translate Cat",
                                artPrompt: L10n.text("Cat talking into a microphone"),
                                artSymbol: "waveform",
                                eyebrow: L10n.text("Analyze"),
                                title: L10n.text("Read %@'s signals.", displayCatName),
                                subtitle: L10n.text("Hold your phone nearby and get a careful interpretation of each vocal signal."),
                                features: [
                                    OnboardingFeature(
                                        icon: "waveform",
                                        title: L10n.text("Recording real sound"),
                                        detail: L10n.text("Recording lasts only while your finger stays down"),
                                        tint: MimiTheme.primary
                                    ),
                                    OnboardingFeature(
                                        icon: "quote.bubble.fill",
                                        title: L10n.text("Capture useful context"),
                                        detail: L10n.text("Context makes every vocalization easier to read."),
                                        tint: MimiTheme.primaryInk
                                    ),
                                    OnboardingFeature(
                                        icon: "clock.arrow.circlepath",
                                        title: L10n.text("Moments over time"),
                                        detail: L10n.text("Tap any sound bubble to replay the moment."),
                                        tint: MimiTheme.success
                                    )
                                ]
                            )
                        case .learn:
                            storyPage(
                                assetName: "Onboarding Learn Cat",
                                artPrompt: L10n.text("Cat reading a tiny book"),
                                artSymbol: "book.pages.fill",
                                eyebrow: L10n.text("Learn"),
                                title: L10n.text("Understand %@'s world.", displayCatName),
                                subtitle: L10n.text("Short, useful lessons help you spot the signals behind every sound and behavior."),
                                features: [
                                    OnboardingFeature(
                                        icon: "eye.fill",
                                        title: L10n.text("Notice the signals before the sound"),
                                        detail: L10n.text("Use these clues together, not as isolated rules."),
                                        tint: MimiTheme.primary
                                    ),
                                    OnboardingFeature(
                                        icon: "fork.knife",
                                        title: L10n.text("Notice routine changes"),
                                        detail: L10n.text("A familiar routine helps small changes stand out."),
                                        tint: MimiTheme.primaryInk
                                    ),
                                    OnboardingFeature(
                                        icon: "cross.case.fill",
                                        title: L10n.text("Spot changes early and know when to seek help."),
                                        detail: L10n.text("Record only meaningful changes and follow up when concerned."),
                                        tint: MimiTheme.success
                                    )
                                ]
                            )
                        case .sounds:
                            storyPage(
                                assetName: "Onboarding Sounds Cat",
                                artPrompt: L10n.text("Cat wearing tiny headphones"),
                                artSymbol: "speaker.wave.3.fill",
                                eyebrow: L10n.text("Sounds"),
                                title: L10n.text("Speak a little more cat."),
                                subtitle: L10n.text("Explore common vocal patterns and the context that can change their meaning."),
                                features: [
                                    OnboardingFeature(
                                        icon: "heart.fill",
                                        title: L10n.text("Soft purrs"),
                                        detail: L10n.text("Often relaxed, but always read with posture."),
                                        tint: MimiTheme.primary
                                    ),
                                    OnboardingFeature(
                                        icon: "fork.knife",
                                        title: L10n.text("Routine calls"),
                                        detail: L10n.text("Timing and repetition can point to habits."),
                                        tint: MimiTheme.primaryInk
                                    ),
                                    OnboardingFeature(
                                        icon: "sparkles",
                                        title: L10n.text("Short trills"),
                                        detail: L10n.text("Often greeting or low-pressure contact."),
                                        tint: MimiTheme.success
                                    )
                                ]
                            )
                        case .quiz:
                            storyPage(
                                assetName: "Onboarding Quiz Cat",
                                artPrompt: L10n.text("Cat proudly holding a quiz trophy"),
                                artSymbol: "brain.fill",
                                eyebrow: L10n.text("Quiz"),
                                title: L10n.text("Become %@'s favorite expert.", displayCatName),
                                subtitle: L10n.text("Tiny daily challenges make understanding cat behavior feel effortless."),
                                features: [
                                    OnboardingFeature(icon: "questionmark.circle.fill", title: L10n.text("Daily challenge"), tint: MimiTheme.primary),
                                    OnboardingFeature(icon: "flame.fill", title: L10n.text("Build a streak"), tint: MimiTheme.primaryInk),
                                    OnboardingFeature(icon: "heart.fill", title: L10n.text("Know them better"), tint: MimiTheme.success)
                                ]
                            )
                        case .notifications:
                            storyPage(
                                assetName: "Onboarding Bell Cat",
                                artPrompt: L10n.text("Cat ringing a little bell"),
                                artSymbol: "bell.badge.fill",
                                eyebrow: L10n.text("Stay in tune"),
                                title: L10n.text("%@'s routines, right on time.", displayCatName),
                                subtitle: L10n.text("Get gentle reminders for daily check-ins, new lessons, and little moments worth noticing."),
                                features: [
                                    OnboardingFeature(icon: "heart.fill", title: L10n.text("Only useful, gentle nudges"), tint: MimiTheme.primary),
                                    OnboardingFeature(icon: "bell.slash.fill", title: L10n.text("Change them anytime"), tint: MimiTheme.tertiary)
                                ]
                            )
                        case .interpretationNotice:
                            storyPage(
                                assetName: "Onboarding Translate Cat",
                                artPrompt: L10n.text("Cat listening carefully"),
                                artSymbol: "waveform",
                                eyebrow: L10n.text("Good to know"),
                                title: L10n.text("Playful interpretations, not literal translations."),
                                subtitle: L10n.text("Mimi is made for fun and connection. It uses sound patterns and context to suggest what a vocalization might mean."),
                                features: [
                                    OnboardingFeature(
                                        icon: "waveform",
                                        title: L10n.text("Built from sound cues"),
                                        detail: L10n.text("Tone, rhythm, and the context you add."),
                                        tint: MimiTheme.primary
                                    ),
                                    OnboardingFeature(
                                        icon: "sparkles",
                                        title: L10n.text("For entertainment"),
                                        detail: L10n.text("Results are not scientifically validated."),
                                        tint: MimiTheme.primaryInk
                                    )
                                ]
                            )
                        case .paywall:
                            PaywallView(catName: displayCatName, onComplete: onComplete)
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .task {
            await hideSplashAfterOpeningAnimation()
        }
        .onChange(of: step) { _, newStep in
            requestReviewIfNeeded(for: newStep)
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func storyPage(
        assetName: String,
        artPrompt: String,
        artSymbol: String,
        eyebrow: String,
        title: String,
        subtitle: String,
        features: [OnboardingFeature]
    ) -> some View {
        if step.usesShowcaseStyle {
            OnboardingShowcasePage(
                assetName: assetName,
                artPrompt: artPrompt,
                artSymbol: artSymbol,
                title: title,
                subtitle: subtitle,
                features: features,
                primaryTitle: step == .notifications
                    ? L10n.text("Enable notifications")
                    : step == .interpretationNotice
                        ? L10n.text("I understand")
                        : L10n.text("Continue"),
                primaryIcon: step == .notifications
                    ? "bell.badge.fill"
                    : step == .interpretationNotice
                        ? "checkmark"
                        : "arrow.right",
                secondaryTitle: step == .notifications ? L10n.text("Maybe later") : nil,
                primaryAction: primaryAction,
                secondaryAction: advance
            )
        } else {
            legacyStoryPage(
                assetName: assetName,
                artPrompt: artPrompt,
                artSymbol: artSymbol,
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle,
                features: features
            )
        }
    }

    private func legacyStoryPage(
        assetName: String,
        artPrompt: String,
        artSymbol: String,
        eyebrow: String,
        title: String,
        subtitle: String,
        features: [OnboardingFeature]
    ) -> some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let hasFeatures = !features.isEmpty

                VStack(spacing: hasFeatures ? 14 : 18) {
                    Color.clear
                        .frame(height: hasFeatures ? 2 : 8)

                    OnboardingCatArtwork(
                        assetName: assetName,
                        prompt: artPrompt,
                        symbol: artSymbol
                    )
                    .frame(height: storyArtHeight(availableHeight: proxy.size.height, hasFeatures: hasFeatures))

                    OnboardingQuestionBlock(
                        eyebrow: eyebrow,
                        title: title,
                        subtitle: subtitle
                    )

                    if hasFeatures {
                        OnboardingFeatureRow(features: features)
                            .padding(.horizontal, 28)
                            .padding(.top, 2)
                    }

                    Spacer(minLength: hasFeatures ? 4 : 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            OnboardingFooter(
                primaryTitle: step == .notifications ? L10n.text("Enable notifications") : L10n.text("Continue"),
                primaryIcon: step == .notifications ? "bell.badge.fill" : "arrow.right",
                secondaryTitle: step == .notifications ? L10n.text("Maybe later") : nil,
                isShowcaseStyle: false,
                primaryAction: primaryAction,
                secondaryAction: advance
            )
        }
    }

    @MainActor
    private func hideSplashAfterOpeningAnimation() async {
        guard isShowingSplash else { return }

        try? await Task.sleep(nanoseconds: 1_350_000_000)
        guard !Task.isCancelled, isShowingSplash else { return }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
            isShowingSplash = false
        }
    }

    private func storyArtHeight(availableHeight: CGFloat, hasFeatures: Bool) -> CGFloat {
        if step == .welcome {
            return min(252, max(190, availableHeight * 0.42))
        }

        return min(176, max(126, availableHeight * (hasFeatures ? 0.28 : 0.34)))
    }

    private func requestReviewIfNeeded(for step: OnboardingStep) {
        guard step == .sounds, !hasRequestedOnboardingReview else { return }
        hasRequestedOnboardingReview = true
        requestReview()
    }

    private func primaryAction() {
        if step == .notifications {
            Task {
                _ = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                advance()
            }
        } else {
            advance()
        }
    }

    private func finishNameStep() {
        catName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        advance()
    }

    private func advance() {
        guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            step = nextStep
        }
    }

    private func goBack() {
        guard let previousStep = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            step = previousStep
        }
    }

    private var displayCatName: String {
        let trimmedName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? L10n.text("your cat") : trimmedName
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case name
    case profile
    case translate
    case learn
    case sounds
    case quiz
    case notifications
    case interpretationNotice
    case paywall
}

private extension OnboardingStep {
    var usesShowcaseStyle: Bool {
        rawValue > OnboardingStep.name.rawValue
    }
}

private struct OnboardingSplashView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(MimiTheme.primary.opacity(0.18), lineWidth: 8)
                    .scaleEffect(isAnimating ? 1.10 : 0.90)
                    .opacity(isAnimating ? 0.16 : 0.58)

                Circle()
                    .fill(MimiTheme.secondary.opacity(0.72))
                    .frame(width: 184, height: 184)

                OnboardingCatArtwork(
                    assetName: "Onboarding Welcome Cat",
                    prompt: L10n.text("Welcome to Mimi"),
                    symbol: "pawprint.fill"
                )
                .frame(height: 154)
                .scaleEffect(isAnimating ? 1.03 : 0.97)
                .rotationEffect(.degrees(isAnimating ? 1.5 : -1.5))
            }
            .frame(width: 232, height: 232)

            Text("Mimi")
                .font(.mimi(size: 34, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MimiTheme.primaryInk.opacity(index == 1 ? 0.80 : 0.42))
                        .frame(width: 7, height: 7)
                        .scaleEffect(isAnimating ? 1.25 : 0.72)
                        .animation(
                            .easeInOut(duration: 0.72)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.12),
                            value: isAnimating
                        )
                }
            }
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct CatNamePage: View {
    @Binding var catName: String
    let action: () -> Void

    @FocusState private var isNameFocused: Bool

    private var isNameEmpty: Bool {
        catName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                OnboardingQuestionBlock(
                    eyebrow: L10n.text("A little personalization"),
                    title: L10n.text("What's your cat's name?"),
                    subtitle: L10n.text("Mimi will use it throughout your interpretations, lessons, and daily moments.")
                )
                .padding(.top, 8)

                HStack(spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(MimiTheme.primaryInk)

                    TextField(L10n.text("e.g. Mochi"), text: $catName)
                        .font(.mimi(size: 20, weight: .heavy))
                        .foregroundStyle(MimiTheme.onSurface)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.continue)
                        .focused($isNameFocused)
                        .onSubmit {
                            guard !isNameEmpty else { return }
                            action()
                        }
                }
                .padding(.horizontal, 18)
                .frame(height: 62)
                .softCard(cornerRadius: 24)
                .padding(.horizontal, 20)

                Spacer(minLength: 8)

                OnboardingCatArtwork(
                    assetName: "Onboarding Name Cat",
                    prompt: L10n.text("Cat waiting for their name"),
                    symbol: "pencil"
                )
                .frame(height: 230)

                Spacer(minLength: 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            OnboardingFooter(
                primaryTitle: isNameEmpty ? L10n.text("Add a name to continue") : L10n.text("Meet %@", catName.trimmingCharacters(in: .whitespacesAndNewlines)),
                primaryIcon: "arrow.right",
                secondaryTitle: nil,
                isPrimaryDisabled: isNameEmpty,
                primaryAction: action,
                secondaryAction: {}
            )
        }
    }
}

private struct CatProfileSelectionPage: View {
    let catName: String
    @Binding var selection: String
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 760
            let artSize = min(isCompact ? 146 : 220, max(138, proxy.size.width - 172))

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompact ? 14 : 18) {
                        OnboardingProfileArtworkStage(assetName: selection, size: artSize)

                        OnboardingShowcaseQuestionBlock(
                            eyebrow: L10n.text("Make it theirs"),
                            title: L10n.text("Pick %@'s best side.", catName),
                            subtitle: L10n.text("Choose a profile picture for interpretations, history, and personalized moments.")
                        )

                        ProfileChoiceGrid(selection: $selection)
                            .padding(.top, isCompact ? 0 : 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, isCompact ? 4 : 18)
                    .padding(.bottom, 18)
                }

                OnboardingFooter(
                    primaryTitle: L10n.text("That's %@", catName),
                    primaryIcon: "arrow.right",
                    secondaryTitle: nil,
                    isShowcaseStyle: true,
                    primaryAction: action,
                    secondaryAction: {}
                )
            }
        }
    }
}

private struct OnboardingShowcasePage: View {
    let assetName: String
    let artPrompt: String
    let artSymbol: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
    let primaryTitle: String
    let primaryIcon: String
    let secondaryTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 760
            let footerHeight: CGFloat = secondaryTitle == nil ? 85 : 122

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        OnboardingEditorialHero(
                            assetName: assetName,
                            prompt: artPrompt,
                            symbol: artSymbol,
                            title: title,
                            subtitle: subtitle,
                            isCompact: isCompact
                        )

                        if !features.isEmpty {
                            OnboardingShowcaseFeatureList(features: features, isCompact: isCompact)
                                .padding(.top, isCompact ? 24 : 30)
                        }

                        Spacer(minLength: isCompact ? 12 : 18)
                    }
                    .frame(minHeight: max(0, proxy.size.height - footerHeight), alignment: .top)
                    .frame(maxWidth: 540)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isCompact ? 18 : 24)
                    .padding(.bottom, isCompact ? 4 : 10)
                }

                OnboardingFooter(
                    primaryTitle: primaryTitle,
                    primaryIcon: primaryIcon,
                    secondaryTitle: secondaryTitle,
                    isShowcaseStyle: true,
                    primaryAction: primaryAction,
                    secondaryAction: secondaryAction
                )
            }
        }
    }
}

private struct OnboardingEditorialHero: View {
    let assetName: String
    let prompt: String
    let symbol: String
    let title: String
    let subtitle: String
    let isCompact: Bool

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: isCompact ? 12 : 16) {
                Text(title.withoutTrailingPeriod)
                    .font(.mimi(size: isCompact ? 30 : 34, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)
                    .lineSpacing(-2)
                    .frame(maxWidth: isCompact ? 250 : 300)

                Text(subtitle)
                    .font(.mimi(size: isCompact ? 16 : 18, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
                    .lineSpacing(isCompact ? 4 : 6)
                    .frame(maxWidth: isCompact ? 330 : 410)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, isCompact ? 86 : 102)

            OnboardingCatArtwork(
                assetName: assetName,
                prompt: prompt,
                symbol: symbol,
                horizontalPadding: 0
            )
            .frame(
                width: isCompact ? 76 : 88,
                height: isCompact ? 76 : 88
            )
            .clipShape(.rect(cornerRadius: isCompact ? 2 : 3))
            .shadow(color: MimiTheme.shadowTint.opacity(0.32), radius: 14, y: 10)
            .padding(.top, isCompact ? 4 : 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isCompact ? 238 : 274, alignment: .top)
    }
}

private struct OnboardingArtworkStage: View {
    let assetName: String
    let prompt: String
    let symbol: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(MimiTheme.surfaceContainerLowest.opacity(0.42))

            OnboardingCatArtwork(
                assetName: assetName,
                prompt: prompt,
                symbol: symbol
            )
        }
        .frame(width: size, height: size)
        .shadow(color: MimiTheme.shadowTint.opacity(0.34), radius: 28, y: 20)
    }
}

private struct OnboardingProfileArtworkStage: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(MimiTheme.surfaceContainerLowest.opacity(0.42))

            CatProfileAvatar(assetName: assetName, size: size * 0.72, showsShadow: true)
        }
        .frame(width: size, height: size)
        .shadow(color: MimiTheme.shadowTint.opacity(0.34), radius: 28, y: 20)
    }
}

private struct OnboardingShowcaseQuestionBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(eyebrow)
                .font(.mimi(size: 11, weight: .heavy))
                .foregroundStyle(MimiTheme.primary)
                .textCase(.uppercase)
                .tracking(3.4)
                .lineLimit(1)

            Text(title.withoutTrailingPeriod)
                .font(.mimi(size: 31, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.70)
                .lineSpacing(-1)

            Text(subtitle)
                .font(.mimi(size: 17, weight: .medium))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.64))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.76)
                .lineSpacing(5)
        }
        .padding(.horizontal, 8)
    }
}

private struct OnboardingShowcaseFeatureList: View {
    let features: [OnboardingFeature]
    let isCompact: Bool

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: isCompact ? 10 : 14) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                OnboardingShowcaseFeatureCard(feature: feature, isCompact: isCompact)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 12)
                    .animation(
                        .spring(response: 0.44, dampingFraction: 0.84)
                            .delay(Double(index) * 0.075),
                        value: hasAppeared
                    )
            }
        }
        .onAppear {
            hasAppeared = false
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
    }
}

private struct OnboardingShowcaseFeatureCard: View {
    let feature: OnboardingFeature
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: isCompact ? 20 : 24) {
            Image(systemName: feature.icon)
                .font(.system(size: isCompact ? 20 : 24, weight: .medium))
                .foregroundStyle(feature.tint)
                .frame(width: isCompact ? 50 : 58, height: isCompact ? 50 : 58)
                .background(
                    LinearGradient(
                        colors: [
                            feature.tint.opacity(0.34),
                            feature.tint.opacity(0.10),
                            MimiTheme.secondary.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .circle
                )
                .overlay {
                    Circle()
                        .stroke(feature.tint.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: feature.tint.opacity(0.22), radius: 9, y: 5)

            VStack(alignment: .leading, spacing: isCompact ? 3 : 5) {
                Text(feature.title.withoutTrailingPeriod)
                    .font(.mimi(size: isCompact ? 15 : 17, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

                if let detail = feature.detail {
                    Text(detail)
                        .font(.mimi(size: isCompact ? 12.5 : 14, weight: .bold))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                        .lineSpacing(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, isCompact ? 22 : 28)
        .padding(.vertical, isCompact ? 14 : 17)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 88 : 102)
        .background(MimiTheme.surfaceContainerLowest.opacity(0.58), in: .rect(cornerRadius: isCompact ? 28 : 32))
        .overlay {
            RoundedRectangle(cornerRadius: isCompact ? 28 : 32, style: .continuous)
                .stroke(.white.opacity(0.90), lineWidth: 1)
        }
        .shadow(color: MimiTheme.shadowTint.opacity(0.18), radius: isCompact ? 16 : 20, y: isCompact ? 9 : 12)
    }
}

private struct ProfileChoiceGrid: View {
    @Binding var selection: String

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CatProfileOption.choices) { option in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                        selection = option.assetName
                    }
                } label: {
                    CatProfileAvatar(
                        assetName: option.assetName,
                        size: 58,
                        showsShadow: selection == option.assetName
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 82)
                    .background(
                        selection == option.assetName ? MimiTheme.secondary : MimiTheme.surfaceContainerLowest.opacity(0.88),
                        in: .rect(cornerRadius: 26)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                selection == option.assetName ? MimiTheme.primary : .white.opacity(0.72),
                                lineWidth: selection == option.assetName ? 2 : 1
                            )
                    }
                    .shadow(color: MimiTheme.shadowTint.opacity(selection == option.assetName ? 0.26 : 0.16), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("Choose profile picture"))
            }
        }
    }
}

private struct OnboardingHeader: View {
    let step: OnboardingStep
    let goBack: () -> Void
    let close: () -> Void

    var body: some View {
        let buttonSize: CGFloat = 52

        HStack(spacing: 12) {
            if step == .paywall {
                OnboardingHeaderIconButton(
                    systemName: "xmark",
                    size: buttonSize,
                    action: close,
                    accessibilityLabel: L10n.text("Close Premium")
                )
            } else {
                OnboardingHeaderIconButton(
                    systemName: "chevron.left",
                    size: buttonSize,
                    action: goBack,
                    accessibilityLabel: L10n.text("Go back")
                )
                .opacity(step == .welcome ? 0 : 1)
                .disabled(step == .welcome)
            }

            Spacer()

            Color.clear
                .frame(width: buttonSize, height: buttonSize)
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }
}

private struct OnboardingHeaderIconButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void
    let accessibilityLabel: String

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(MimiTheme.surfaceContainerLowest.opacity(0.94))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.86), lineWidth: 1)
                    }
                    .shadow(color: MimiTheme.shadowTint.opacity(0.22), radius: 12, y: 7)

                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MimiTheme.primaryInk)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct OnboardingQuestionBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Text(eyebrow)
                .font(.mimi(size: 11, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .textCase(.uppercase)
                .tracking(1.6)
                .lineLimit(1)

            Text(title)
                .font(.mimi(size: 30, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .lineSpacing(-2)

            Text(subtitle)
                .font(.mimi(size: 13.5, weight: .medium))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .lineSpacing(2)
        }
        .padding(.horizontal, 28)
    }
}

private struct OnboardingCatArtwork: View {
    let assetName: String
    let prompt: String
    let symbol: String
    var horizontalPadding: CGFloat = 20

    private var fallbackAssetName: String {
        switch assetName {
        case "Onboarding Translate Cat": "Cat Mascot (4)"
        case "Onboarding Bell Cat": "Cat Mascot (5)"
        case "Paywall Crown Cat": "Cat Mascot (6)"
        default: "Cat Mascot"
        }
    }

    private var image: UIImage? {
        MimiImageAsset.image(named: assetName) ?? MimiImageAsset.image(named: fallbackAssetName)
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 94, weight: .bold))
                    .foregroundStyle(MimiTheme.primaryInk)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(prompt)
    }
}

private struct OnboardingFeature {
    let icon: String
    let title: String
    var detail: String? = nil
    let tint: Color
}

private extension String {
    var withoutTrailingPeriod: String {
        last == "." ? String(dropLast()) : self
    }
}

private struct OnboardingFeatureRow: View {
    let features: [OnboardingFeature]

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(feature.tint)
                        .frame(width: 30, height: 30)
                        .background(feature.tint.opacity(0.12), in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.mimi(size: 12.5, weight: .heavy))
                            .foregroundStyle(MimiTheme.onSurface.opacity(0.82))
                            .lineLimit(feature.detail == nil ? 2 : 1)

                        if let detail = feature.detail {
                            Text(detail)
                                .font(.mimi(size: 10.5, weight: .bold))
                                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.72))
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(
                    .spring(response: 0.44, dampingFraction: 0.84)
                        .delay(Double(index) * 0.075),
                    value: hasAppeared
                )
            }
        }
        .onAppear {
            hasAppeared = false
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
    }
}

private struct OnboardingFooter: View {
    let primaryTitle: String
    let primaryIcon: String
    let secondaryTitle: String?
    var isPrimaryDisabled = false
    var isShowcaseStyle = false
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    @ViewBuilder
    var body: some View {
        if isShowcaseStyle {
            showcaseFooter
        } else {
            legacyFooter
        }
    }

    private var showcaseFooter: some View {
        VStack(spacing: 5) {
            Button(action: primaryAction) {
                HStack(spacing: 12) {
                    Text(primaryTitle)
                    Image(systemName: primaryIcon)
                        .font(.system(size: 19, weight: .semibold))
                }
                .font(.mimi(size: 20, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(MimiTheme.primary, in: .capsule)
                .shadow(color: MimiTheme.primary.opacity(0.28), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(isPrimaryDisabled)
            .opacity(isPrimaryDisabled ? 0.50 : 1)

            if let secondaryTitle {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.mimi(size: 14, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.78))
                    .frame(height: 32)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 5)
        .padding(.bottom, 12)
    }

    private var legacyFooter: some View {
        VStack(spacing: 8) {
            Button(action: primaryAction) {
                HStack(spacing: 9) {
                    Text(primaryTitle)
                    Image(systemName: primaryIcon)
                }
                .font(.mimi(size: 16, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .buttonStyle(.glassProminent)
            .tint(MimiTheme.primary)
            .disabled(isPrimaryDisabled)
            .opacity(isPrimaryDisabled ? 0.55 : 1)

            if let secondaryTitle {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.mimi(size: 13, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .frame(height: 34)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

private struct PaywallView: View {
    let catName: String
    let onComplete: () -> Void

    @StateObject private var store = PremiumStore()
    @State private var selectedPlan: PremiumPlan = .annual
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 760
            let horizontalPadding: CGFloat = proxy.size.width < 390 ? 18 : 24
            let artSize: CGFloat = isCompact ? 128 : 154

            VStack(spacing: isCompact ? 9 : 12) {
                VStack(spacing: isCompact ? 7 : 10) {
                    PaywallArtwork(size: artSize)

                    VStack(spacing: isCompact ? 3 : 5) {
                        Text(L10n.text("Unlock %@'s language", catName))
                            .font(.mimi(size: isCompact ? 27 : 31, weight: .heavy))
                            .foregroundStyle(MimiTheme.primaryInk)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        Text(L10n.text("Join Premium and understand every meow."))
                            .font(.mimi(size: isCompact ? 12.5 : 14, weight: .medium))
                            .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: isCompact ? 8 : 10),
                            GridItem(.flexible(), spacing: isCompact ? 8 : 10)
                        ],
                        spacing: isCompact ? 8 : 10
                    ) {
                        PaywallBenefit(
                            icon: "translate",
                            title: L10n.text("Unlimited translations"),
                            detail: L10n.text("Understand every meow"),
                            tint: MimiTheme.primary,
                            isCompact: isCompact
                        )
                        PaywallBenefit(
                            icon: "nosign",
                            title: L10n.text("Ad-free experience"),
                            detail: L10n.text("No interruptions"),
                            tint: MimiTheme.outline,
                            isCompact: isCompact
                        )
                        PaywallBenefit(
                            icon: "clock.arrow.circlepath",
                            title: L10n.text("Full history"),
                            detail: L10n.text("Replay every moment"),
                            tint: MimiTheme.tertiary,
                            isCompact: isCompact
                        )
                        PaywallBenefit(
                            icon: "person.wave.2.fill",
                            title: L10n.text("Premium voices"),
                            detail: L10n.text("More ways to speak"),
                            tint: MimiTheme.primaryInk,
                            isCompact: isCompact
                        )
                    }

                    VStack(spacing: isCompact ? 7 : 9) {
                        ForEach(PremiumPlan.allCases) { plan in
                            PaywallPlanRow(
                                plan: plan,
                                priceLine: store.priceLine(for: plan),
                                isSelected: selectedPlan == plan,
                                isCompact: isCompact
                            ) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                                    selectedPlan = plan
                                }
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.mimi(size: 10.5, weight: .bold))
                            .foregroundStyle(MimiTheme.error)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalPadding)

                Button(action: purchase) {
                    HStack(spacing: 12) {
                        if store.isPurchasing {
                            ProgressView()
                                .tint(MimiTheme.primaryInk)
                        } else {
                            Text(store.callToAction(for: selectedPlan))
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 19, weight: .semibold))
                        }
                    }
                    .font(.mimi(size: 20, weight: .heavy))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(MimiTheme.primary, in: .capsule)
                    .shadow(color: MimiTheme.primary.opacity(0.28), radius: 18, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(store.isPurchasing || !store.hasPackage(for: selectedPlan))
                .opacity(store.isPurchasing || !store.hasPackage(for: selectedPlan) ? 0.50 : 1)
                .padding(.horizontal, 18)

                Text(store.purchaseDisclosure(for: selectedPlan))
                    .font(.mimi(size: isCompact ? 8.5 : 9.5, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .lineLimit(isCompact ? 3 : 2)
                    .minimumScaleFactor(0.74)
                    .padding(.horizontal, 24)

                HStack(spacing: isCompact ? 12 : 18) {
                    Button(L10n.text("Restore purchases"), action: restore)
                        .disabled(store.isPurchasing)
                    Text("•")
                    Link(
                        L10n.text("Terms of use"),
                        destination: MimiLegalLinks.terms
                    )
                    Text("•")
                    Link(
                        L10n.text("Privacy policy"),
                        destination: MimiLegalLinks.privacyPolicy
                    )
                }
                .font(.mimi(size: isCompact ? 9.5 : 10.5, weight: .bold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .accessibilityElement(children: .contain)
                .frame(height: isCompact ? 27 : 31)
                .padding(.horizontal, 12)
                .padding(.bottom, isCompact ? 3 : 7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            if let loadingError = await store.loadOfferings() {
                errorMessage = loadingError
            }
        }
    }

    private func purchase() {
        errorMessage = nil

        Task {
            do {
                if try await store.purchase(selectedPlan) {
                    onComplete()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        errorMessage = nil

        Task {
            do {
                if try await store.restorePurchases() {
                    onComplete()
                } else {
                    errorMessage = L10n.text("No active Mimi+ purchase was found.")
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct PaywallArtwork: View {
    let size: CGFloat

    var body: some View {
        OnboardingCatArtwork(
            assetName: "Paywall Crown Cat",
            prompt: L10n.text("Cat proudly wearing a tiny crown"),
            symbol: "crown.fill",
            horizontalPadding: 0
        )
        .frame(width: size, height: size)
        .shadow(color: MimiTheme.shadowTint.opacity(0.28), radius: 12, y: 7)
    }
}

private struct PaywallBenefit: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 6 : 8) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 18 : 21, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: isCompact ? 42 : 48, height: isCompact ? 42 : 48)
                .background(tint.opacity(0.14), in: .circle)

            VStack(spacing: 2) {
                Text(title)
                    .font(.mimi(size: isCompact ? 11.5 : 13, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(detail)
                    .font(.mimi(size: isCompact ? 9 : 10, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isCompact ? 126 : 138)
        .background(MimiTheme.surfaceContainerLowest.opacity(0.76), in: .rect(cornerRadius: isCompact ? 24 : 28))
        .overlay {
            RoundedRectangle(cornerRadius: isCompact ? 24 : 28, style: .continuous)
                .stroke(.white.opacity(0.76), lineWidth: 1)
        }
        .shadow(color: MimiTheme.shadowTint.opacity(0.17), radius: isCompact ? 10 : 14, y: isCompact ? 5 : 7)
    }
}

private struct PaywallPlanRow: View {
    let plan: PremiumPlan
    let priceLine: String
    let isSelected: Bool
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 10 : 12) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? MimiTheme.primaryInk : MimiTheme.outline.opacity(0.82),
                            lineWidth: 2
                        )

                    if isSelected {
                        Circle()
                            .fill(MimiTheme.primaryInk)
                            .padding(5)
                    }
                }
                .frame(width: isCompact ? 22 : 24, height: isCompact ? 22 : 24)

                VStack(alignment: .leading, spacing: isCompact ? 1 : 3) {
                    Text(plan.title)
                        .font(.mimi(size: isCompact ? 14 : 16, weight: .heavy))
                        .foregroundStyle(MimiTheme.onSurface)
                        .lineLimit(1)

                    Text(priceLine)
                        .font(.mimi(size: isCompact ? 10.5 : 12, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                if let badge = plan.badge {
                    Text(badge)
                        .font(.mimi(size: isCompact ? 8.5 : 9.5, weight: .heavy))
                        .foregroundStyle(MimiTheme.primaryInk)
                        .padding(.horizontal, isCompact ? 8 : 10)
                        .padding(.vertical, isCompact ? 5 : 6)
                        .background(MimiTheme.tertiary, in: .capsule)
                }
            }
            .padding(.horizontal, isCompact ? 14 : 16)
            .frame(height: isCompact ? 62 : 68)
            .background(
                isSelected ? MimiTheme.primary.opacity(0.30) : MimiTheme.surfaceContainerLowest.opacity(0.72),
                in: .rect(cornerRadius: isCompact ? 22 : 26)
            )
            .overlay {
                RoundedRectangle(cornerRadius: isCompact ? 22 : 26, style: .continuous)
                    .stroke(
                        isSelected ? MimiTheme.primaryInk : MimiTheme.outlineVariant.opacity(0.34),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(color: MimiTheme.shadowTint.opacity(0.13), radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private enum PremiumPlan: String, CaseIterable, Identifiable {
    case annual
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .annual: L10n.text("Yearly")
        case .monthly: L10n.text("Monthly")
        }
    }

    var badge: String? {
        self == .annual ? L10n.text("Best Value") : nil
    }

    func package(in offering: Offering) -> Package? {
        switch self {
        case .annual:
            return offering.annual
        case .monthly:
            return offering.monthly
        }
    }
}

@MainActor
private final class PremiumStore: ObservableObject {
    @Published private(set) var packages: [PremiumPlan: Package] = [:]
    @Published private(set) var introEligibility: [PremiumPlan: IntroEligibilityStatus] = [:]
    @Published private(set) var isPurchasing = false

    func loadOfferings() async -> String? {
        guard Purchases.isConfigured else {
            return PurchaseError.missingAPIKey.localizedDescription
        }

        do {
            guard let offering = try await Purchases.shared.offerings().current else {
                throw PurchaseError.offeringUnavailable
            }

            var loadedPackages: [PremiumPlan: Package] = [:]
            for plan in PremiumPlan.allCases {
                loadedPackages[plan] = plan.package(in: offering)
            }

            guard !loadedPackages.isEmpty else {
                throw PurchaseError.offeringUnavailable
            }

            packages = loadedPackages

            let productIdentifiers = loadedPackages.values.map(\.storeProduct.productIdentifier)
            let eligibilityByProduct = await Purchases.shared.checkTrialOrIntroDiscountEligibility(
                productIdentifiers: productIdentifiers
            )
            introEligibility = loadedPackages.reduce(into: [:]) { result, entry in
                result[entry.key] = eligibilityByProduct[entry.value.storeProduct.productIdentifier]?.status
                    ?? .unknown
            }
            return nil
        } catch {
            packages = [:]
            introEligibility = [:]
            return error.localizedDescription
        }
    }

    func hasPackage(for plan: PremiumPlan) -> Bool {
        packages[plan] != nil
    }

    func priceLine(for plan: PremiumPlan) -> String {
        guard let package = packages[plan] else {
            return L10n.text("Unavailable")
        }

        let price = package.localizedPriceString
        let renewalPeriod = periodText(package.storeProduct.subscriptionPeriod)

        if let trialPeriod = freeTrialPeriod(for: plan) {
            return L10n.text(
                "%@ free trial, then %@ / %@",
                periodText(trialPeriod.period, multiplier: trialPeriod.multiplier),
                price,
                renewalPeriod
            )
        }

        return L10n.text("%@ / %@", price, renewalPeriod)
    }

    func callToAction(for plan: PremiumPlan) -> String {
        freeTrialPeriod(for: plan) == nil
            ? L10n.text("Subscribe now")
            : L10n.text("Start free trial")
    }

    func purchaseDisclosure(for plan: PremiumPlan) -> String {
        guard let package = packages[plan] else {
            return L10n.text("Prices and subscription terms are provided by Apple.")
        }

        let price = package.localizedPriceString
        let renewalPeriod = periodText(package.storeProduct.subscriptionPeriod)

        if let trialPeriod = freeTrialPeriod(for: plan) {
            return L10n.text(
                "%@ free, then %@ per %@. Auto-renews until canceled in Apple ID settings.",
                periodText(trialPeriod.period, multiplier: trialPeriod.multiplier),
                price,
                renewalPeriod
            )
        }

        return L10n.text(
            "%@ per %@. Auto-renews until canceled in Apple ID settings.",
            price,
            renewalPeriod
        )
    }

    func purchase(_ plan: PremiumPlan) async throws -> Bool {
        guard Purchases.isConfigured else {
            throw PurchaseError.missingAPIKey
        }
        guard let package = packages[plan] else {
            throw PurchaseError.packageUnavailable
        }

        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else {
            return false
        }

        guard hasActiveAccess(result.customerInfo) else {
            throw PurchaseError.entitlementInactive
        }

        return true
    }

    func restorePurchases() async throws -> Bool {
        guard Purchases.isConfigured else {
            throw PurchaseError.missingAPIKey
        }

        isPurchasing = true
        defer { isPurchasing = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        return hasActiveAccess(customerInfo)
    }

    private func hasActiveAccess(_ customerInfo: CustomerInfo) -> Bool {
        !customerInfo.entitlements.active.isEmpty
    }

    private func freeTrialPeriod(
        for plan: PremiumPlan
    ) -> (period: RevenueCat.SubscriptionPeriod, multiplier: Int)? {
        guard introEligibility[plan] == .eligible,
              let discount = packages[plan]?.storeProduct.introductoryDiscount,
              discount.type == .introductory,
              discount.paymentMode == .freeTrial else {
            return nil
        }

        return (discount.subscriptionPeriod, max(discount.numberOfPeriods, 1))
    }

    private func periodText(
        _ period: RevenueCat.SubscriptionPeriod?,
        multiplier: Int = 1
    ) -> String {
        guard let period else {
            return L10n.text("subscription period")
        }

        let value = period.value * multiplier
        switch (period.unit, value) {
        case (.day, 1):
            return L10n.text("day")
        case (.week, 1):
            return L10n.text("week")
        case (.month, 1):
            return L10n.text("month")
        case (.year, 1):
            return L10n.text("year")
        case (.day, _):
            return L10n.text("%d days", value)
        case (.week, _):
            return L10n.text("%d weeks", value)
        case (.month, _):
            return L10n.text("%d months", value)
        case (.year, _):
            return L10n.text("%d years", value)
        @unknown default:
            return L10n.text("subscription period")
        }
    }
}

private enum PurchaseError: LocalizedError {
    case missingAPIKey
    case offeringUnavailable
    case packageUnavailable
    case entitlementInactive

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            L10n.text("RevenueCat is not configured. Add the public SDK key to REVENUECAT_API_KEY.")
        case .offeringUnavailable:
            L10n.text("No current RevenueCat offering with Mimi+ packages was found.")
        case .packageUnavailable:
            L10n.text("This Mimi+ plan is not available in the current RevenueCat offering.")
        case .entitlementInactive:
            L10n.text("The purchase completed, but no active RevenueCat entitlement was found.")
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
