import SwiftUI

struct CatProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MonetizationService.self) private var monetizationService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("catName") private var catName = ""
    @AppStorage("catProfileAssetName") private var catProfileAssetName = "Profile Cat 1"
    @AppStorage("catAgeYears") private var catAgeYears = 0
    @AppStorage("catTranslationTone") private var catTranslationTone = "warm"
    @AppStorage("catDailyRecapEnabled") private var catDailyRecapEnabled = true
    @AppStorage("catDailyRecapTime") private var catDailyRecapTime = "9:00"
    @AppStorage("catListeningSensitivity") private var catListeningSensitivity = "balanced"

    var body: some View {
        NavigationStack {
            ZStack {
                MimiBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        CatProfileAvatar(assetName: catProfileAssetName, size: 180)

                        VStack(spacing: 5) {
                            Text(displayCatName)
                                .font(.mimi(size: 34, weight: .heavy))
                                .foregroundStyle(MimiTheme.onSurface)

                            Text(L10n.text("Tune %@'s interpretation profile", displayCatName))
                                .font(.mimi(size: 13, weight: .bold))
                                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                        }

                        ProfileEditorSection(title: L10n.text("Cat details")) {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(MimiTheme.primaryInk)
                                        .frame(width: 40, height: 40)
                                        .background(MimiTheme.primary.opacity(0.12), in: .rect(cornerRadius: 14))

                                    TextField(L10n.text("Cat name"), text: $catName)
                                        .font(.mimi(size: 17, weight: .heavy))
                                        .foregroundStyle(MimiTheme.onSurface)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
                                }
                                .padding(16)
                                .softCard(cornerRadius: 24)

                                Stepper(value: $catAgeYears, in: 0...25) {
                                    ProfileValueLabel(
                                        icon: "calendar",
                                        title: L10n.text("Age"),
                                        value: ageText
                                    )
                                }
                                .padding(16)
                                .softCard(cornerRadius: 24)
                            }
                        }

                        ProfileEditorSection(title: L10n.text("Avatar")) {
                            LazyVGrid(columns: avatarColumns, spacing: 12) {
                                ForEach(CatProfileOption.choices) { option in
                                    AvatarChoiceButton(
                                        option: option,
                                        isSelected: catProfileAssetName == option.assetName
                                    ) {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                                            catProfileAssetName = option.assetName
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .softCard(cornerRadius: 24)
                        }

                        ProfileEditorSection(title: L10n.text("Interpretation settings")) {
                            VStack(spacing: 12) {
                                Picker(L10n.text("Interpretation style"), selection: $catTranslationTone) {
                                    Text(L10n.text("Warm")).tag("warm")
                                    Text(L10n.text("Playful")).tag("playful")
                                    Text(L10n.text("Direct")).tag("direct")
                                }
                                .pickerStyle(.segmented)

                                Picker(L10n.text("Listening sensitivity"), selection: $catListeningSensitivity) {
                                    Text(L10n.text("Calm")).tag("calm")
                                    Text(L10n.text("Balanced")).tag("balanced")
                                    Text(L10n.text("Sensitive")).tag("sensitive")
                                }
                                .pickerStyle(.segmented)

                                Toggle(isOn: $catDailyRecapEnabled) {
                                    ProfileValueLabel(
                                        icon: "bell.badge.fill",
                                        title: L10n.text("Daily recap"),
                                        value: catDailyRecapEnabled ? catDailyRecapTime : L10n.text("Off")
                                    )
                                }
                                .tint(MimiTheme.primary)

                                if catDailyRecapEnabled {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(MimiTheme.primaryInk)
                                            .frame(width: 40, height: 40)
                                            .background(MimiTheme.primary.opacity(0.12), in: .rect(cornerRadius: 14))

                                        TextField(L10n.text("9:00"), text: $catDailyRecapTime)
                                            .font(.mimi(size: 16, weight: .heavy))
                                            .foregroundStyle(MimiTheme.onSurface)
                                            .keyboardType(.numbersAndPunctuation)
                                    }
                                }
                            }
                            .padding(16)
                            .softCard(cornerRadius: 24)
                        }

                        if monetizationService.isPrivacyOptionsRequired {
                            ProfileEditorSection(title: L10n.text("Privacy")) {
                                Button {
                                    Task {
                                        await monetizationService.presentPrivacyOptions()
                                    }
                                } label: {
                                    ProfileSetting(
                                        icon: "hand.raised.fill",
                                        title: L10n.text("Privacy choices"),
                                        value: L10n.text("Manage")
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

#if DEBUG
                        VStack(spacing: 12) {
                            Button {
                                dismiss()
                                hasCompletedOnboarding = false
                            } label: {
                                ProfileSetting(icon: "arrow.counterclockwise", title: L10n.text("Replay onboarding"), value: L10n.text("Debug"))
                            }
                            .buttonStyle(.plain)
                        }
#endif
                    }
                    .padding(20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle(L10n.text("Personalization"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Done")) { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(34)
    }

    private var displayCatName: String {
        let trimmedName = catName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? L10n.text("your cat") : trimmedName
    }

    private var ageText: String {
        catAgeYears == 0 ? L10n.text("Unknown") : L10n.text("%d years", catAgeYears)
    }

    private var avatarColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }
}

private struct ProfileEditorSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.mimi(size: 10, weight: .heavy))
                .foregroundStyle(MimiTheme.primaryInk)
                .tracking(1.2)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileValueLabel: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MimiTheme.primaryInk)
                .frame(width: 40, height: 40)
                .background(MimiTheme.primary.opacity(0.12), in: .rect(cornerRadius: 14))

            Text(title)
                .font(.mimi(size: 15, weight: .bold))
                .foregroundStyle(MimiTheme.onSurface)

            Spacer()

            Text(value)
                .font(.mimi(size: 13, weight: .bold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
        }
    }
}

private struct AvatarChoiceButton: View {
    let option: CatProfileOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                CatProfileAvatar(assetName: option.assetName, size: 74)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(MimiTheme.primaryInk, MimiTheme.primary)
                        .background(MimiTheme.surfaceContainerLowest, in: .circle)
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text("Choose profile picture"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.mimi(size: 22, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
            Text(label)
                .font(.mimi(size: 10, weight: .bold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .softCard(cornerRadius: 24)
    }
}

private struct ProfileSetting: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MimiTheme.primaryInk)
                .frame(width: 40, height: 40)
                .background(MimiTheme.primary.opacity(0.12), in: .rect(cornerRadius: 14))

            Text(title)
                .font(.mimi(size: 15, weight: .bold))
                .foregroundStyle(MimiTheme.onSurface)

            Spacer()

            Text(value)
                .font(.mimi(size: 13, weight: .bold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
        }
        .padding(16)
        .softCard(cornerRadius: 24)
    }
}
