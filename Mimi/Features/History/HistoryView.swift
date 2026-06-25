import SwiftUI

struct HistoryView: View {
    @Environment(ConversationStore.self) private var conversationStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MimiBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.text("Your signal notes,\nkept here."))
                            .font(.mimi(size: 31, weight: .heavy))
                            .foregroundStyle(MimiTheme.onSurface)
                            .padding(.bottom, 8)

                        if conversationStore.messages.isEmpty {
                            EmptyHistoryView()
                        } else {
                            ForEach(conversationStore.messages.reversed()) { message in
                                MomentRow(message: message)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.text("Mimi moments"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Done")) { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(34)
    }
}

private struct MomentRow: View {
    let message: CatConversationMessage

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.13), in: .rect(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(message.translationText)
                    .font(.mimi(size: 15, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurface)
                    .lineLimit(2)

                if !message.interpretationDetail.isEmpty {
                    Text(message.interpretationDetail)
                        .font(.mimi(size: 11.5, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                        .lineLimit(2)
                }

                Text(L10n.text("%@ • %@", message.confidence, message.createdAt.formatted(date: .abbreviated, time: .shortened)))
                    .font(.mimi(size: 11, weight: .semibold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .softCard(cornerRadius: 24)
    }

    private var icon: String {
        if message.kind == .photo {
            return "camera.fill"
        }

        return switch message.detectedMood {
        case "Attention": "exclamationmark.bubble.fill"
        case "Playful": "sparkles"
        case "Hungry": "fork.knife"
        case "Affection": "heart.fill"
        case "Curious": "magnifyingglass"
        default: "checkmark.seal.fill"
        }
    }

    private var tint: Color {
        if message.kind == .photo {
            return MimiTheme.primaryInk
        }

        return switch message.detectedMood {
        case "Attention": MimiTheme.error
        case "Playful": MimiTheme.tertiary
        case "Hungry": MimiTheme.primary
        case "Affection": MimiTheme.primaryInk
        case "Curious": MimiTheme.success
        default: MimiTheme.outline
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(MimiTheme.primaryInk)

            Text(L10n.text("No saved recordings yet"))
                .font(.mimi(size: 19, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)

            Text(L10n.text("Hold to record on the Analyze tab, and Mimi will keep each sound with its local interpretation here."))
                .font(.mimi(size: 14, weight: .medium))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .lineSpacing(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard(cornerRadius: 24)
    }
}

#Preview {
    HistoryView()
        .environment(ConversationStore.preview)
}
