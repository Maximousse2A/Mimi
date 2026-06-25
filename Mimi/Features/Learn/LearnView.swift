import SwiftUI
import UIKit

struct LearnView: View {
    @Environment(MonetizationService.self) private var monetizationService
    @State private var selectedCategory: LearnCategory = .all
    @State private var selectedTopic: LearnTopic?
    @State private var didReadSelectedTopic = false

    private let categories = LearnCategory.allCases
    private let topics = LearnTopic.samples

    private var filteredTopics: [LearnTopic] {
        selectedCategory == .all ? topics : topics.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
            MimiBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                        PageHeading(
                            eyebrow: L10n.text("Mimi academy"),
                            title: L10n.text("Understand your cat,\nbeautifully."),
                            subtitle: L10n.text("20 deeper guides for everyday cat behavior, care, and wellbeing.")
                        )

                    ScrollView(.horizontal, showsIndicators: false) {
                        GlassEffectContainer(spacing: 10) {
                            HStack(spacing: 10) {
                                ForEach(categories, id: \.self) { category in
                                    FilterChip(
                                        title: category.localizedTitle,
                                        isSelected: category == selectedCategory
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    LazyVStack(spacing: 16) {
                        ForEach(filteredTopics) { topic in
                            LearnTopicCard(topic: topic) {
                                didReadSelectedTopic = false
                                selectedTopic = topic
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 26)
                }
                .padding(.top, 18)
            }
        }
        .sheet(item: $selectedTopic, onDismiss: recordArticleReadIfNeeded) { topic in
            LearnDetailView(topic: topic) {
                didReadSelectedTopic = true
            }
        }
    }

    private func recordArticleReadIfNeeded() {
        guard didReadSelectedTopic else { return }

        didReadSelectedTopic = false
        Task {
            await monetizationService.record(.articleRead)
        }
    }
}

private struct LearnTopicCard: View {
    let topic: LearnTopic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                LearnArtwork(topic: topic)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(topic.category.localizedTitle.uppercased())
                            .font(.mimi(size: 10, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(topic.tint)

                        Spacer()

                        Text(topic.readTime)
                            .font(.mimi(size: 11, weight: .bold))
                            .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    }

                    Text(topic.title)
                        .font(.mimi(size: 20, weight: .heavy))
                        .foregroundStyle(MimiTheme.onSurface)
                        .multilineTextAlignment(.leading)

                    Text(topic.subtitle)
                        .font(.mimi(size: 13, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.stack.fill")
                            .foregroundStyle(topic.tint)

                        Text(L10n.text("%d field notes", topic.sections.count))

                        Spacer()

                        Text(L10n.text("Open lesson"))
                            .foregroundStyle(topic.tint)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(topic.tint)
                    }
                    .font(.mimi(size: 11, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .padding(.top, 2)
                }
                .padding(16)
            }
            .background(MimiTheme.surfaceContainerLowest, in: .rect(cornerRadius: 32))
            .clipShape(.rect(cornerRadius: 32))
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(MimiTheme.outlineVariant.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: .white.opacity(0.90), radius: 18, x: -8, y: -8)
            .shadow(color: MimiTheme.shadowTint.opacity(0.52), radius: 22, x: 10, y: 12)
        }
        .buttonStyle(.plain)
    }
}

private struct LearnArtwork: View {
    let topic: LearnTopic
    var height: CGFloat = 190

    var body: some View {
        Group {
            if let artwork = MimiImageAsset.image(named: topic.artworkName) {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else {
                TopicVisual(symbol: topic.symbol, tint: topic.tint, height: height)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct LearnDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let topic: LearnTopic
    let didReachEnd: () -> Void
    @State private var hasReportedEnd = false

    var body: some View {
        NavigationStack {
            ZStack {
                MimiBackground()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        LearnArtwork(topic: topic, height: 220)
                            .clipShape(.rect(cornerRadius: 28))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                LessonPill(title: topic.category.localizedTitle, symbol: topic.symbol, tint: topic.tint)
                                LessonPill(title: topic.readTime, symbol: "clock.fill", tint: MimiTheme.onSurfaceVariant)
                            }

                            Text(topic.title)
                                .font(.mimi(size: 30, weight: .heavy))
                                .foregroundStyle(MimiTheme.onSurface)

                            Text(topic.subtitle)
                                .font(.mimi(size: 16, weight: .medium))
                                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                                .lineSpacing(3)
                        }

                        BigIdeaCard(topic: topic)

                        LessonContextBlock(paragraphs: topic.context)

                        LessonSectionHeading(
                            eyebrow: L10n.text("Look closer"),
                            title: L10n.text("What to notice"),
                            subtitle: L10n.text("Examples from real cat life, plus what the human can adjust.")
                        )

                        VStack(spacing: 12) {
                            ForEach(topic.sections) { section in
                                LessonIdeaCard(section: section, tint: topic.tint)
                            }
                        }

                        LessonSectionHeading(
                            eyebrow: L10n.text("Make it useful"),
                            title: topic.actionTitle,
                            subtitle: L10n.text("A small experiment for the next time the moment appears.")
                        )

                        LessonActionCard(actions: topic.actions, tint: topic.tint)

                        LessonNoteCard(note: topic.note, tint: topic.tint)

                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                guard !hasReportedEnd else { return }
                                hasReportedEnd = true
                                didReachEnd()
                            }
                    }
                    .padding(20)
                    .padding(.bottom, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Done")) { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }
}

private struct LessonPill: View {
    let title: String
    let symbol: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.mimi(size: 11, weight: .heavy))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(tint.opacity(0.10), in: .capsule)
    }
}

private struct BigIdeaCard: View {
    let topic: LearnTopic

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MimiTheme.primaryInk)
                .frame(width: 40, height: 40)
                .background(MimiTheme.primary, in: .circle)

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("THE BIG IDEA"))
                    .font(.mimi(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(topic.tint)

                Text(topic.bigIdea)
                    .font(.mimi(size: 16, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurface)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(topic.tint.opacity(0.10), in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(topic.tint.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct LessonContextBlock: View {
    let paragraphs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LessonSectionHeading(
                eyebrow: L10n.text("Context"),
                title: L10n.text("Why it matters"),
                subtitle: L10n.text("The background that turns a clue into a better decision.")
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.mimi(size: 15, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.88))
                        .lineSpacing(4)
                }
            }
        }
    }
}

private struct LessonSectionHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.mimi(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(MimiTheme.primaryInk)

            Text(title)
                .font(.mimi(size: 23, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)

            Text(subtitle)
                .font(.mimi(size: 13, weight: .medium))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .lineSpacing(2)
        }
    }
}

private struct LessonIdeaCard: View {
    let section: LearnSection
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: section.symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.11), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(section.title)
                    .font(.mimi(size: 16, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)

                Text(section.body)
                    .font(.mimi(size: 13, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .softCard(cornerRadius: 32)
    }
}

private struct LessonActionCard: View {
    let actions: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.mimi(size: 12, weight: .heavy))
                        .foregroundStyle(MimiTheme.primaryInk)
                        .frame(width: 28, height: 28)
                        .background(MimiTheme.primary, in: .circle)

                    Text(action)
                        .font(.mimi(size: 14, weight: .bold))
                        .foregroundStyle(MimiTheme.onSurface.opacity(0.86))
                        .lineSpacing(3)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .softCard(cornerRadius: 32)
    }
}

private struct LessonNoteCard: View {
    let note: LearnNote
    let tint: Color

    private var noteTint: Color {
        note.isSafetyNote ? MimiTheme.error : tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: note.isSafetyNote ? "cross.case.fill" : "heart.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(noteTint)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.mimi(size: 14, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)

                Text(note.body)
                    .font(.mimi(size: 12, weight: .medium))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(noteTint.opacity(0.09), in: .rect(cornerRadius: 24))
    }
}
