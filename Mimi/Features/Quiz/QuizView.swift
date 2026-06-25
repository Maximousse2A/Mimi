import SwiftUI

struct QuizView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("quizDailyStreak") private var storedDailyStreak = 0
    @AppStorage("quizLastDailyCompletionDay") private var lastDailyCompletionDay = ""
    @AppStorage("quizAnsweredQuestionIDs") private var answeredQuestionIDsData = "[]"
    @AppStorage("quizCorrectQuestionIDs") private var correctQuestionIDsData = "[]"
    @AppStorage("quizDailySelectedAnswers") private var dailySelectedAnswersData = "{}"
    @State private var selectedTopic: QuizTopic?
    @State private var currentDate = Date()

    private let topics = QuizContent.topics

    private var dailyQuestion: QuizQuestion {
        QuizContent.dailyQuestion(on: currentDate)
    }

    private var answeredQuestionIDs: Set<String> {
        Self.decodedIDSet(from: answeredQuestionIDsData)
    }

    private var correctQuestionIDs: Set<String> {
        Self.decodedIDSet(from: correctQuestionIDsData)
    }

    private var dailySelectedAnswers: [String: Int] {
        Self.decodedAnswerMap(from: dailySelectedAnswersData)
    }

    private var selectedDailyAnswer: Int? {
        guard isDailyCompletedToday else { return nil }
        return dailySelectedAnswers[dailyQuestion.id]
    }

    private var isDailyCompletedToday: Bool {
        lastDailyCompletionDay == Self.dayKey(for: currentDate)
    }

    private var displayedStreak: Int {
        guard !lastDailyCompletionDay.isEmpty else { return 0 }

        let today = Self.dayKey(for: currentDate)
        if lastDailyCompletionDay == today {
            return storedDailyStreak
        }

        if lastDailyCompletionDay == Self.yesterdayKey(relativeTo: currentDate) {
            return storedDailyStreak
        }

        return 0
    }

    var body: some View {
        ZStack {
            MimiBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeading(
                        eyebrow: L10n.text("Cat expert quiz"),
                        title: L10n.text("How fluent are\nyou in cat?"),
                        subtitle: L10n.text("Daily questions and playful topic quizzes for sharper cat instincts.")
                    )

                    ProgressOverviewCard(
                        streak: displayedStreak,
                        answeredCount: answeredQuestionIDs.count,
                        masteredCount: correctQuestionIDs.count
                    )
                    .padding(.horizontal, 20)

                    DailyQuestionCard(
                        question: dailyQuestion,
                        selectedAnswer: selectedDailyAnswer,
                        streak: displayedStreak,
                        isCompletedToday: isDailyCompletedToday
                    ) { answerIndex in
                        answerDailyQuestion(answerIndex)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        QuizSectionHeading(
                            eyebrow: L10n.text("Practice by topic"),
                            title: L10n.text("Choose a quiz"),
                            subtitle: L10n.text("Each quiz has 15 questions and is easy to replay.")
                        )
                        .padding(.horizontal, 20)

                        LazyVStack(spacing: 14) {
                            ForEach(topics) { topic in
                                TopicQuizCard(
                                    topic: topic,
                                    answeredCount: progressCount(for: topic),
                                    correctCount: correctCount(for: topic)
                                ) {
                                    selectedTopic = topic
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 26)
                }
                .padding(.top, topContentPadding)
            }
        }
        .sheet(item: $selectedTopic) { topic in
            QuizSessionView(topic: topic) { question, answerIndex in
                recordAnswer(question, answerIndex: answerIndex)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            currentDate = Date()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                currentDate = Date()
            }
        }
    }

    private func answerDailyQuestion(_ answerIndex: Int) {
        recordAnswer(dailyQuestion, answerIndex: answerIndex)
        saveDailySelection(answerIndex, for: dailyQuestion)

        let now = Date()
        currentDate = now
        let today = Self.dayKey(for: now)
        guard lastDailyCompletionDay != today else { return }

        if lastDailyCompletionDay == Self.yesterdayKey(relativeTo: now) {
            storedDailyStreak += 1
        } else {
            storedDailyStreak = 1
        }

        lastDailyCompletionDay = today
    }

    private func recordAnswer(_ question: QuizQuestion, answerIndex: Int) {
        var answered = answeredQuestionIDs
        answered.insert(question.id)
        answeredQuestionIDsData = Self.encodedIDSet(answered)

        if answerIndex == question.correctAnswerIndex {
            var correct = correctQuestionIDs
            correct.insert(question.id)
            correctQuestionIDsData = Self.encodedIDSet(correct)
        }
    }

    private func saveDailySelection(_ answerIndex: Int, for question: QuizQuestion) {
        var selectedAnswers = dailySelectedAnswers
        selectedAnswers[question.id] = answerIndex
        dailySelectedAnswersData = Self.encodedAnswerMap(selectedAnswers)
    }

    private func progressCount(for topic: QuizTopic) -> Int {
        topic.questions.filter { answeredQuestionIDs.contains($0.id) }.count
    }

    private func correctCount(for topic: QuizTopic) -> Int {
        topic.questions.filter { correctQuestionIDs.contains($0.id) }.count
    }

    private var topContentPadding: CGFloat {
#if DEBUG
        58
#else
        18
#endif
    }

    private static func decodedIDSet(from rawValue: String) -> Set<String> {
        guard
            let data = rawValue.data(using: .utf8),
            let values = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(values)
    }

    private static func encodedIDSet(_ set: Set<String>) -> String {
        guard
            let data = try? JSONEncoder().encode(set.sorted()),
            let value = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return value
    }

    private static func decodedAnswerMap(from rawValue: String) -> [String: Int] {
        guard
            let data = rawValue.data(using: .utf8),
            let values = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            return [:]
        }

        return values
    }

    private static func encodedAnswerMap(_ map: [String: Int]) -> String {
        guard
            let data = try? JSONEncoder().encode(map),
            let value = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return value
    }

    private static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private static func yesterdayKey(relativeTo date: Date) -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        return dayKey(for: yesterday)
    }
}

struct QuizTopic: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let artworkName: String
    let tint: Color
    let questions: [QuizQuestion]
}

struct QuizQuestion: Identifiable {
    let id: String
    let difficulty: String
    let prompt: String
    let answers: [String]
    let correctAnswerIndex: Int
    let explanation: String
}

enum QuizContent {
    static let topics = [
        topic(
            id: "behavior",
            title: "Behavior",
            subtitle: "Body language, greetings, and comfort signals.",
            symbol: "eye.fill",
            artworkName: "Academy Behavior Signals",
            tint: MimiTheme.primaryInk,
            questions: [
                question(
                    id: "behavior-slow-blink",
                    difficulty: "Easy",
                    prompt: "Which signal usually means a cat feels safe and affectionate?",
                    answers: ["A slow blink", "A tucked tail", "Flattened ears", "A loud hiss"],
                    correctAnswerIndex: 0,
                    explanation: "Exactly. A slow blink is a quiet sign of trust."
                ),
                question(
                    id: "behavior-tail-lash",
                    difficulty: "Medium",
                    prompt: "A fast, sharp tail lash usually means you should do what?",
                    answers: ["Pause and lower the pressure", "Pet faster", "Pick the cat up", "Move their bowl"],
                    correctAnswerIndex: 0,
                    explanation: "A sharp tail lash can show rising intensity. Pausing gives the cat room to settle."
                ),
                question(
                    id: "behavior-shy-cat",
                    difficulty: "Easy",
                    prompt: "What helps a shy cat build trust most reliably?",
                    answers: ["Choice and predictable routines", "Blocking every hiding spot", "Long surprise cuddles", "Louder encouragement"],
                    correctAnswerIndex: 0,
                    explanation: "Choice, distance, and repeatable calm moments make trust easier to build."
                ),
                question(
                    id: "behavior-flattened-ears",
                    difficulty: "Easy",
                    prompt: "Flattened ears and a tense crouch usually suggest what?",
                    answers: ["Deep relaxation", "Fear or defensive discomfort", "A request for food", "An invitation to be picked up"],
                    correctAnswerIndex: 1,
                    explanation: "Flattened ears with a tense, lowered body often mean the cat needs more distance and less pressure."
                ),
                question(
                    id: "behavior-belly",
                    difficulty: "Medium",
                    prompt: "A cat rolls over and shows their belly. What is the safest interpretation?",
                    answers: ["They always want a belly rub", "They are asking to be carried", "They may feel safe, but touch is still their choice", "They want rough play"],
                    correctAnswerIndex: 2,
                    explanation: "Showing the belly can signal trust or relaxation, but it is not automatic permission to touch."
                ),
                question(
                    id: "behavior-petting-pause",
                    difficulty: "Medium",
                    prompt: "During petting, your cat's skin twitches and tail starts lashing. What should you do?",
                    answers: ["Hold them still", "Move to the belly", "Pet faster", "Pause and let them choose whether to continue"],
                    correctAnswerIndex: 3,
                    explanation: "Skin twitching and tail lashing can be early overstimulation signs. A pause prevents the cat from needing a stronger warning."
                ),
                question(
                    id: "behavior-cheek-rub",
                    difficulty: "Easy",
                    prompt: "What does a relaxed cheek rub against you often do?",
                    answers: ["Leaves familiar scent and supports a social greeting", "Shows the cat is lost", "Means the cat cannot see clearly", "Always asks for a meal"],
                    correctAnswerIndex: 0,
                    explanation: "Cats have scent glands around the face. A relaxed rub can mix scent and reinforce familiarity."
                ),
                question(
                    id: "behavior-wide-pupils",
                    difficulty: "Medium",
                    prompt: "Why should very wide pupils never be read on their own?",
                    answers: ["They only appear during sleep", "Light, play, fear, and pain can all affect them", "They always mean aggression", "They reveal a cat's age"],
                    correctAnswerIndex: 1,
                    explanation: "Pupil size changes with light and arousal, so posture, location, and the rest of the face matter too."
                ),
                question(
                    id: "behavior-hiding",
                    difficulty: "Easy",
                    prompt: "A newly arrived cat stays in a hiding place. What is the most helpful response?",
                    answers: ["Pull them out for social time", "Block the hiding place", "Keep resources nearby and allow a safe retreat", "Invite several guests to help"],
                    correctAnswerIndex: 2,
                    explanation: "A protected retreat helps an overwhelmed cat regulate stress and begin exploring at their own pace."
                ),
                question(
                    id: "behavior-introductions",
                    difficulty: "Hard",
                    prompt: "What is the best first stage when introducing two cats?",
                    answers: ["Share one food bowl", "Place them nose-to-nose", "Let them settle it through chasing", "Use separate spaces and exchange scent first"],
                    correctAnswerIndex: 3,
                    explanation: "Separate spaces and gradual scent exchange build familiarity before the pressure of direct contact."
                ),
                question(
                    id: "behavior-whiskers",
                    difficulty: "Medium",
                    prompt: "Whiskers pulled tightly back with a tense face can indicate what?",
                    answers: ["Worry, discomfort, or defensive tension", "Guaranteed sleepiness", "A friendly greeting every time", "A preference for wet food"],
                    correctAnswerIndex: 0,
                    explanation: "Pulled-back whiskers can join other facial tension signals. Check the ears, eyes, posture, and context."
                ),
                question(
                    id: "behavior-purring",
                    difficulty: "Medium",
                    prompt: "Which statement about purring is most accurate?",
                    answers: ["Purring always proves happiness", "Cats may also purr when stressed, unwell, or self-soothing", "Only kittens purr", "Purring means the cat wants touch"],
                    correctAnswerIndex: 1,
                    explanation: "Purring often occurs during comfort, but it can also accompany stress or illness. The whole pattern matters."
                ),
                question(
                    id: "behavior-kneading",
                    difficulty: "Easy",
                    prompt: "A relaxed cat kneading a soft blanket is commonly showing what?",
                    answers: ["A need to escape", "Territorial aggression", "Comfort or a familiar soothing behavior", "A litter-box problem"],
                    correctAnswerIndex: 2,
                    explanation: "Kneading is a common comfort behavior carried from kittenhood, especially when the body is loose and settled."
                ),
                question(
                    id: "behavior-scratching",
                    difficulty: "Easy",
                    prompt: "Why do cats scratch surfaces?",
                    answers: ["Only to damage furniture", "Because their claws are itchy", "To ask for punishment", "To stretch, maintain claws, and leave visual and scent marks"],
                    correctAnswerIndex: 3,
                    explanation: "Scratching is normal communication and body care. Suitable scratchers make the behavior easier to direct."
                ),
                question(
                    id: "behavior-resource-blocking",
                    difficulty: "Hard",
                    prompt: "In a multi-cat home, one cat quietly blocks a doorway to the litter boxes. Why does it matter?",
                    answers: ["It can create resource pressure even without a fight", "It means the cats are playing", "It improves litter habits", "It proves the blocked cat is shy"],
                    correctAnswerIndex: 0,
                    explanation: "Staring or blocking access can create chronic social pressure. Add routes and separated resources so no cat controls access."
                )
            ]
        ),
        topic(
            id: "nutrition",
            title: "Nutrition",
            subtitle: "Food, water, treats, and calmer mealtimes.",
            symbol: "fork.knife",
            artworkName: "Academy Calm Mealtime",
            tint: MimiTheme.primary,
            questions: [
                question(
                    id: "nutrition-routine",
                    difficulty: "Easy",
                    prompt: "Why is a steady feeding rhythm useful?",
                    answers: ["It makes real changes easier to notice", "It makes cats need less water", "It replaces vet advice", "It guarantees every meal is finished"],
                    correctAnswerIndex: 0,
                    explanation: "A consistent routine creates a baseline, so appetite or behavior changes stand out sooner."
                ),
                question(
                    id: "nutrition-water",
                    difficulty: "Medium",
                    prompt: "What is the best first step for learning a cat's water preference?",
                    answers: ["Offer fresh water in a few quiet places", "Remove all but one bowl", "Only use water near food", "Change every bowl daily"],
                    correctAnswerIndex: 0,
                    explanation: "Multiple fresh, quiet water options help you see what your cat naturally chooses."
                ),
                question(
                    id: "nutrition-treats",
                    difficulty: "Easy",
                    prompt: "Treats work best when they are used how?",
                    answers: ["With a clear purpose and small portions", "As the main meal", "Only when the cat begs", "In unlimited amounts"],
                    correctAnswerIndex: 0,
                    explanation: "Small, purposeful rewards support training and care without crowding out balanced meals."
                ),
                question(
                    id: "nutrition-water-location",
                    difficulty: "Easy",
                    prompt: "Where is a water bowl often easiest for a cautious cat to use?",
                    answers: ["Beside a noisy appliance", "In a quiet place with a clear view", "Inside the litter area", "Where another cat can block it"],
                    correctAnswerIndex: 1,
                    explanation: "A quiet, accessible water station lets a cat drink without noise, ambush points, or social pressure."
                ),
                question(
                    id: "nutrition-appetite-change",
                    difficulty: "Hard",
                    prompt: "Your cat suddenly stops eating. What is the best response?",
                    answers: ["Wait several days without checking", "Offer only treats", "Contact a veterinary professional promptly", "Force food into their mouth"],
                    correctAnswerIndex: 2,
                    explanation: "A sudden loss of appetite can become serious quickly in cats. Prompt veterinary guidance is the safest next step."
                ),
                question(
                    id: "nutrition-weight",
                    difficulty: "Medium",
                    prompt: "What is the most reliable way to notice a gradual weight change?",
                    answers: ["Judge from fur fluffiness", "Compare appetite once a year", "Look only at the face", "Track weight and body condition consistently"],
                    correctAnswerIndex: 3,
                    explanation: "Regular measurements and body-condition checks reveal trends that can be hard to see day to day."
                ),
                question(
                    id: "nutrition-multicat-feeding",
                    difficulty: "Medium",
                    prompt: "One cat finishes quickly and hovers over another cat's bowl. What can help?",
                    answers: ["Feed them in separate spaces", "Move the bowls closer", "Use one larger shared bowl", "Remove the slower cat's meal"],
                    correctAnswerIndex: 0,
                    explanation: "Separate feeding spaces reduce competition and make each cat's actual appetite easier to observe."
                ),
                question(
                    id: "nutrition-food-transition",
                    difficulty: "Easy",
                    prompt: "How should most routine food changes be introduced?",
                    answers: ["All at once at a stressful time", "Gradually while watching appetite and digestion", "By withholding water", "By mixing in unlimited treats"],
                    correctAnswerIndex: 1,
                    explanation: "A gradual transition is often easier on digestion and gives you time to notice whether the new food suits the cat."
                ),
                question(
                    id: "nutrition-treat-balance",
                    difficulty: "Medium",
                    prompt: "Why should treats remain a small part of a cat's overall diet?",
                    answers: ["Cats stop tasting them", "Treats contain too much water", "They can displace nutritionally complete food", "They prevent all training"],
                    correctAnswerIndex: 2,
                    explanation: "Too many extras can unbalance the diet or add unnoticed calories, even when each treat is small."
                ),
                question(
                    id: "nutrition-bowl-shape",
                    difficulty: "Easy",
                    prompt: "A cat repeatedly pulls food out of a deep bowl. What simple change is worth trying?",
                    answers: ["A taller narrow cup", "A moving bowl", "A bowl beside the litter box", "A wide, shallow dish"],
                    correctAnswerIndex: 3,
                    explanation: "Some cats are more comfortable eating from a stable, wide dish that does not crowd the face and whiskers."
                ),
                question(
                    id: "nutrition-wet-dry",
                    difficulty: "Medium",
                    prompt: "Which statement about wet and dry cat food is most useful?",
                    answers: ["Either can fit when the overall diet is complete and appropriate for the cat", "Dry food never contains nutrients", "Wet food suits every medical condition", "The most expensive option is always best"],
                    correctAnswerIndex: 0,
                    explanation: "The right choice depends on nutritional completeness, the individual cat, hydration, health needs, and veterinary guidance."
                ),
                question(
                    id: "nutrition-leftovers",
                    difficulty: "Easy",
                    prompt: "What should you do with moist food left sitting out for a long time?",
                    answers: ["Top it up indefinitely", "Discard it and serve a fresh portion", "Mix it into the water bowl", "Leave it until the next day"],
                    correctAnswerIndex: 1,
                    explanation: "Fresh portions and clean dishes reduce spoilage and make changes in appetite easier to measure."
                ),
                question(
                    id: "nutrition-toxic-aromatics",
                    difficulty: "Hard",
                    prompt: "Which common cooking ingredients should not be offered to cats?",
                    answers: ["Plain cooked pumpkin", "Unseasoned cooked meat", "Onion and garlic", "A veterinary diet"],
                    correctAnswerIndex: 2,
                    explanation: "Onion, garlic, and related plants can be toxic to cats, including in powders and seasoned foods."
                ),
                question(
                    id: "nutrition-milk",
                    difficulty: "Easy",
                    prompt: "Why is a bowl of cow's milk usually a poor everyday treat for an adult cat?",
                    answers: ["It always causes allergies", "It removes vitamins", "It makes water unsafe", "Many adult cats do not tolerate lactose well"],
                    correctAnswerIndex: 3,
                    explanation: "Many adult cats digest lactose poorly, so milk can cause stomach or bowel upset."
                ),
                question(
                    id: "nutrition-puzzle-feeder",
                    difficulty: "Medium",
                    prompt: "How should you introduce a food puzzle to a cat who has never used one?",
                    answers: ["Start easy and make it harder gradually", "Hide every meal immediately", "Use it only when the cat is very hungry", "Shake it loudly near the cat"],
                    correctAnswerIndex: 0,
                    explanation: "An easy first success builds confidence. Difficulty can increase after the cat understands how food is released."
                )
            ]
        ),
        topic(
            id: "health",
            title: "Health",
            subtitle: "Spot changes early and know when to seek help.",
            symbol: "cross.case.fill",
            artworkName: "Academy Unusual Sounds",
            tint: MimiTheme.success,
            questions: [
                question(
                    id: "health-sound-change",
                    difficulty: "Medium",
                    prompt: "What makes a new sound more meaningful as a health clue?",
                    answers: ["A clear change from the cat's normal pattern", "The sound being cute", "The sound happening once during play", "The cat sitting near a window"],
                    correctAnswerIndex: 0,
                    explanation: "Changes from normal, especially with appetite, breathing, litter-box, or energy shifts, deserve attention."
                ),
                question(
                    id: "health-litter-urgent",
                    difficulty: "Hard",
                    prompt: "Which litter-box sign can be urgent?",
                    answers: ["Repeated straining with little or no urine", "Digging before using the box", "Covering waste carefully", "Using the same corner every time"],
                    correctAnswerIndex: 0,
                    explanation: "Repeated straining with little or no urine can be an emergency and needs urgent veterinary care."
                ),
                question(
                    id: "health-vet-notes",
                    difficulty: "Easy",
                    prompt: "What should you bring to a vet conversation about a change?",
                    answers: ["Timing, frequency, and short notes or videos", "Only a guess at the cause", "A new food recommendation", "A list of unrelated tricks"],
                    correctAnswerIndex: 0,
                    explanation: "Clear notes, timing, and short videos help the veterinary team understand patterns that may not appear in clinic."
                ),
                question(
                    id: "health-open-mouth-breathing",
                    difficulty: "Hard",
                    prompt: "Which breathing sign needs urgent veterinary attention?",
                    answers: ["A quiet sigh before sleep", "Open-mouth or visibly labored breathing", "Sniffing a new blanket", "Purring during a greeting"],
                    correctAnswerIndex: 1,
                    explanation: "Open-mouth or labored breathing in a cat can be an emergency. Minimize stress and seek urgent veterinary help."
                ),
                question(
                    id: "health-grooming-change",
                    difficulty: "Medium",
                    prompt: "Why can a sudden change in grooming matter?",
                    answers: ["It proves the cat dislikes water", "It only reflects the season", "Pain, illness, stress, or mobility changes can affect grooming", "It means the coat is fully clean"],
                    correctAnswerIndex: 2,
                    explanation: "Both reduced grooming and excessive grooming can be meaningful changes when compared with the cat's usual pattern."
                ),
                question(
                    id: "health-vomiting",
                    difficulty: "Medium",
                    prompt: "When is vomiting more concerning than an isolated mild episode?",
                    answers: ["When it happens near a rug", "When the cat looks embarrassed", "When food is a new color", "When it repeats or comes with lethargy, pain, or appetite loss"],
                    correctAnswerIndex: 3,
                    explanation: "Repeated vomiting or vomiting with other changes deserves prompt veterinary advice."
                ),
                question(
                    id: "health-weight-loss",
                    difficulty: "Hard",
                    prompt: "An older cat is eating well but steadily losing weight. What should you do?",
                    answers: ["Arrange a veterinary assessment", "Simply double every meal", "Assume it is normal aging", "Stop tracking the change"],
                    correctAnswerIndex: 0,
                    explanation: "Unexplained weight loss is not a normal change to ignore, even when appetite appears strong."
                ),
                question(
                    id: "health-dental-signs",
                    difficulty: "Medium",
                    prompt: "Which cluster can point to mouth or dental discomfort?",
                    answers: ["Sleeping in sunlight", "Dropping food, bad breath, or chewing on one side", "Stretching after a nap", "Watching birds quietly"],
                    correctAnswerIndex: 1,
                    explanation: "Changes in chewing, food handling, breath, or mouth sensitivity can justify a veterinary dental check."
                ),
                question(
                    id: "health-carrier",
                    difficulty: "Easy",
                    prompt: "What makes a carrier less stressful before a veterinary visit?",
                    answers: ["Only bringing it out during emergencies", "Chasing the cat into it", "Leaving it open with familiar bedding and rewards", "Storing it beside a loud machine"],
                    correctAnswerIndex: 2,
                    explanation: "When the carrier is familiar furniture instead of an alarm signal, calm practice becomes possible."
                ),
                question(
                    id: "health-human-medication",
                    difficulty: "Hard",
                    prompt: "What should you do before giving a cat any human medication?",
                    answers: ["Use half the human dose", "Mix it into milk", "Check an online comment", "Get specific veterinary instructions"],
                    correctAnswerIndex: 3,
                    explanation: "Many common human medicines are dangerous to cats. Only give medication under specific veterinary direction."
                ),
                question(
                    id: "health-senior-baseline",
                    difficulty: "Medium",
                    prompt: "Which change should not be dismissed as 'just getting old'?",
                    answers: ["New difficulty jumping, grooming, eating, or using the litter box", "Preferring a familiar bed", "Sleeping after play", "Watching the same window"],
                    correctAnswerIndex: 0,
                    explanation: "Mobility and routine changes may reflect pain or illness. Senior cats benefit from early assessment and practical support."
                ),
                question(
                    id: "health-squinting",
                    difficulty: "Medium",
                    prompt: "A cat keeps one eye closed and is squinting. What is the safest response?",
                    answers: ["Wait until the next routine visit", "Seek prompt veterinary advice", "Use leftover eye drops", "Rub the eye gently"],
                    correctAnswerIndex: 1,
                    explanation: "Eye problems can be painful and can worsen quickly. Prompt professional advice is safer than home treatment."
                ),
                question(
                    id: "health-limping",
                    difficulty: "Easy",
                    prompt: "What is useful to record when a cat starts limping?",
                    answers: ["Only the cat's mood", "The weather forecast", "When it began, which limb, and a short video if safe", "A list of favorite toys"],
                    correctAnswerIndex: 2,
                    explanation: "Timing, pattern, and video can help a veterinary team assess movement that may look different in the clinic."
                ),
                question(
                    id: "health-fleas",
                    difficulty: "Medium",
                    prompt: "Which sign can fit a flea problem even if you never see a live flea?",
                    answers: ["A clean water bowl", "Slow blinking", "A preference for cardboard", "Itching with tiny dark specks in the coat"],
                    correctAnswerIndex: 3,
                    explanation: "Flea dirt and itching may be easier to notice than a moving flea. Ask a veterinary professional about safe cat-specific control."
                ),
                question(
                    id: "health-weekly-check",
                    difficulty: "Easy",
                    prompt: "What is the purpose of a gentle weekly wellness check?",
                    answers: ["Learn the cat's normal pattern so changes stand out", "Diagnose every illness at home", "Replace veterinary exams", "Force handling practice"],
                    correctAnswerIndex: 0,
                    explanation: "Brief, low-pressure observation of appetite, coat, movement, breathing, and litter habits builds a useful baseline."
                )
            ]
        ),
        topic(
            id: "play",
            title: "Play",
            subtitle: "Make enrichment safer, kinder, and more fun.",
            symbol: "sparkles",
            artworkName: "Academy Play Patterns",
            tint: MimiTheme.tertiary,
            questions: [
                question(
                    id: "play-hunt-rhythm",
                    difficulty: "Easy",
                    prompt: "Good play usually follows which rhythm?",
                    answers: ["Stalk, chase, pounce, and catch", "Chase forever without catching", "Jump as high as possible", "Startle, grab, and stop"],
                    correctAnswerIndex: 0,
                    explanation: "Letting the cat catch the toy keeps play rewarding instead of frustrating."
                ),
                question(
                    id: "play-safety",
                    difficulty: "Medium",
                    prompt: "Which toy habit keeps play safer?",
                    answers: ["Store string-like toys after play", "Leave ribbons out overnight", "Use fingers as prey", "Ignore loose toy pieces"],
                    correctAnswerIndex: 0,
                    explanation: "String, ribbon, elastic, and loose pieces should be stored after supervised play."
                ),
                question(
                    id: "play-senior",
                    difficulty: "Easy",
                    prompt: "How can play be kinder for a senior cat?",
                    answers: ["Keep movement reachable and near the floor", "Demand long sprints", "Only use high jumps", "Make every session longer"],
                    correctAnswerIndex: 0,
                    explanation: "Reachable, stable, shorter play lets senior cats enjoy the game without unnecessary strain."
                ),
                question(
                    id: "play-session-length",
                    difficulty: "Easy",
                    prompt: "What is a good sign that a play session has lasted long enough?",
                    answers: ["The human is bored", "The cat disengages, slows down, or settles", "The toy breaks", "The cat is forced to keep chasing"],
                    correctAnswerIndex: 1,
                    explanation: "Short, satisfying sessions can be better than pushing past the cat's interest or physical comfort."
                ),
                question(
                    id: "play-laser",
                    difficulty: "Medium",
                    prompt: "How can laser-pointer play be made less frustrating?",
                    answers: ["Move it into the cat's eyes", "End while the cat is still searching", "Finish with a toy or treat the cat can physically catch", "Use it on slippery stairs"],
                    correctAnswerIndex: 2,
                    explanation: "A tangible catch gives the hunting sequence a clear ending instead of leaving the cat chasing something impossible to capture."
                ),
                question(
                    id: "play-hands",
                    difficulty: "Easy",
                    prompt: "Why is it better not to teach a kitten that hands are prey?",
                    answers: ["Hands move too slowly", "Kittens dislike people", "It prevents all cuddling", "Biting and grabbing hands can become painful adult habits"],
                    correctAnswerIndex: 3,
                    explanation: "Toys create a clear target for hunting behavior and help keep human skin outside the game."
                ),
                question(
                    id: "play-rotation",
                    difficulty: "Easy",
                    prompt: "What can make familiar toys feel interesting again?",
                    answers: ["Rotate a few toys instead of leaving every toy out", "Wash away every scent daily", "Make all toys identical", "Never move their location"],
                    correctAnswerIndex: 0,
                    explanation: "Rotating safe toys preserves novelty without requiring a constant stream of new objects."
                ),
                question(
                    id: "play-cardboard",
                    difficulty: "Easy",
                    prompt: "Why can a simple cardboard box be valuable enrichment?",
                    answers: ["It replaces the litter box", "It offers hiding, exploring, and ambush opportunities", "It guarantees exercise", "It should be eaten"],
                    correctAnswerIndex: 1,
                    explanation: "A safe box can support choice, concealment, play, and observation at very little cost."
                ),
                question(
                    id: "play-multicat",
                    difficulty: "Medium",
                    prompt: "One cat takes over every wand-toy session. What can help the quieter cat?",
                    answers: ["Move the toy faster between both cats", "Let the bold cat keep every turn", "Offer separate play sessions or more distance", "Remove all toys"],
                    correctAnswerIndex: 2,
                    explanation: "Separate opportunities prevent one cat from controlling the game and let you match each cat's preferred pace."
                ),
                question(
                    id: "play-kitten-proof",
                    difficulty: "Medium",
                    prompt: "Which setup is safest for an energetic kitten?",
                    answers: ["Loose thread on the floor", "Open windows without secure screens", "Tiny pieces that can be swallowed", "Supervised toys plus a kitten-proofed space"],
                    correctAnswerIndex: 3,
                    explanation: "Kittens explore with speed, claws, and mouths. Secure hazards and supervise toys with strings or small parts."
                ),
                question(
                    id: "play-boredom",
                    difficulty: "Medium",
                    prompt: "Which pattern can suggest a cat needs more appropriate enrichment?",
                    answers: ["Repeated restless attention-seeking or ambushing without a good play outlet", "Sleeping after a meal", "Using a scratching post", "Watching birds from a safe window"],
                    correctAnswerIndex: 0,
                    explanation: "Restlessness or misdirected hunting can improve when the cat gets predictable play, exploration, and choice."
                ),
                question(
                    id: "play-after-hunt",
                    difficulty: "Easy",
                    prompt: "What can create a satisfying ending after an active hunting game?",
                    answers: ["A sudden loud noise", "A catch followed by a small meal or treat", "Hiding the toy before any catch", "Immediate forced cuddling"],
                    correctAnswerIndex: 1,
                    explanation: "Catch and food can complete the hunt-eat rhythm and help some cats settle after play."
                ),
                question(
                    id: "play-prey-movement",
                    difficulty: "Medium",
                    prompt: "How should a wand toy usually move to invite stalking?",
                    answers: ["Directly into the cat's face", "In nonstop high circles", "Away from the cat with pauses and changes of direction", "Only under the cat's paws"],
                    correctAnswerIndex: 2,
                    explanation: "Prey-like movement creates distance, disappears briefly, and pauses, giving the cat time to watch and plan."
                ),
                question(
                    id: "play-stop-signals",
                    difficulty: "Medium",
                    prompt: "Which signal means it is wise to lower the intensity of play?",
                    answers: ["A loose sideways hop", "A calm pause", "A successful toy catch", "Panting, repeated frustration, or a tense tail lash"],
                    correctAnswerIndex: 3,
                    explanation: "Intense physical or frustration signals are a cue to pause, cool down, and adjust the next session."
                ),
                question(
                    id: "play-toy-inspection",
                    difficulty: "Easy",
                    prompt: "What should you do with solo toys on a regular basis?",
                    answers: ["Check them for loose, sharp, or swallowable pieces", "Assume they stay safe forever", "Add longer strings", "Place them in food bowls"],
                    correctAnswerIndex: 0,
                    explanation: "Routine inspection catches wear before a loose piece, stuffing, bell, or sharp edge becomes a hazard."
                )
            ]
        )
    ]

    static let allQuestions = topics.flatMap(\.questions)

    static func dailyQuestion(on date: Date = Date(), calendar: Calendar = .current) -> QuizQuestion {
        precondition(!dailyQuestionOrder.isEmpty, "The daily quiz requires at least one question.")

        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? date
        let dayOffset = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: referenceDate),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        let index = positiveModulo(dayOffset, dailyQuestionOrder.count)
        return dailyQuestionOrder[index]
    }

    private static let dailyQuestionOrder = allQuestions.sorted {
        let leftHash = stableHash(for: $0.id)
        let rightHash = stableHash(for: $1.id)
        return leftHash == rightHash ? $0.id < $1.id : leftHash < rightHash
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static func stableHash(for value: String) -> UInt64 {
        value.utf8.reduce(1_469_598_103_934_665_603) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }

    private static func topic(
        id: String,
        title: String,
        subtitle: String,
        symbol: String,
        artworkName: String,
        tint: Color,
        questions: [QuizQuestion]
    ) -> QuizTopic {
        QuizTopic(
            id: id,
            title: L10n.text(title),
            subtitle: L10n.text(subtitle),
            symbol: symbol,
            artworkName: artworkName,
            tint: tint,
            questions: questions
        )
    }

    private static func question(
        id: String,
        difficulty: String,
        prompt: String,
        answers: [String],
        correctAnswerIndex: Int,
        explanation: String
    ) -> QuizQuestion {
        QuizQuestion(
            id: id,
            difficulty: L10n.text(difficulty),
            prompt: L10n.text(prompt),
            answers: answers.map { L10n.text($0) },
            correctAnswerIndex: correctAnswerIndex,
            explanation: L10n.text(explanation)
        )
    }
}

private struct ProgressOverviewCard: View {
    let streak: Int
    let answeredCount: Int
    let masteredCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                QuizArtwork(assetName: "Quiz cat", symbol: "questionmark.bubble.fill", tint: MimiTheme.primary, height: 112)
                    .frame(width: 132)
                    .clipShape(.rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.text("Today's streak"))
                        .font(.mimi(size: 11, weight: .heavy))
                        .foregroundStyle(MimiTheme.primaryInk)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(streakText)
                        .font(.mimi(size: 27, weight: .heavy))
                        .foregroundStyle(MimiTheme.onSurface)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Label(L10n.text("Answer today's question to keep it alive"), systemImage: "flame.fill")
                        .font(.mimi(size: 12, weight: .bold))
                        .foregroundStyle(MimiTheme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                QuizStat(value: "\(answeredCount)", label: L10n.text("answered"))
                QuizStat(value: "\(masteredCount)", label: L10n.text("mastered"))
                QuizStat(value: "\(QuizContent.allQuestions.count)", label: L10n.text("questions"))
            }
        }
        .padding(16)
        .softCard(cornerRadius: 32)
    }

    private var streakText: String {
        streak == 1 ? L10n.text("1-day streak") : L10n.text("%d-day streak", streak)
    }
}

private struct QuizStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.mimi(size: 20, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)

            Text(label)
                .font(.mimi(size: 10, weight: .bold))
                .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                .textCase(.uppercase)
                .tracking(0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(MimiTheme.primary.opacity(0.08), in: .rect(cornerRadius: 18))
    }
}

private struct QuizArtwork: View {
    let assetName: String?
    let symbol: String
    let tint: Color
    let height: CGFloat

    var body: some View {
        Group {
            if let assetName, let artwork = MimiImageAsset.image(named: assetName) {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else {
                TopicVisual(symbol: symbol, tint: tint, height: height)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct QuizSectionHeading: View {
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

private struct DailyQuestionCard: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let streak: Int
    let isCompletedToday: Bool
    let answerAction: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.text("Question of the day"))
                    .font(.mimi(size: 12, weight: .heavy))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()

                Text(isCompletedToday ? L10n.text("Completed today") : question.difficulty)
                    .font(.mimi(size: 11, weight: .bold))
                    .foregroundStyle(isCompletedToday ? MimiTheme.success : MimiTheme.primaryInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isCompletedToday ? MimiTheme.success : MimiTheme.primary).opacity(0.10), in: .capsule)
            }

            Text(question.prompt)
                .font(.mimi(size: 22, weight: .heavy))
                .foregroundStyle(MimiTheme.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(question.answers.indices, id: \.self) { index in
                    QuizAnswerButton(question: question, index: index, selectedAnswer: selectedAnswer) {
                        answerAction(index)
                    }
                    .disabled(selectedAnswer != nil)
                }
            }

            if let selectedAnswer {
                QuizFeedback(question: question, selectedAnswer: selectedAnswer)

                Label(streak == 1 ? L10n.text("Your streak has started.") : L10n.text("Your streak is safe for today."), systemImage: "flame.fill")
                    .font(.mimi(size: 13, weight: .heavy))
                    .foregroundStyle(MimiTheme.primaryInk)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(24)
        .softCard(cornerRadius: 32)
    }
}

private struct TopicQuizCard: View {
    let topic: QuizTopic
    let answeredCount: Int
    let correctCount: Int
    let action: () -> Void

    private var progress: Double {
        guard !topic.questions.isEmpty else { return 0 }
        return Double(answeredCount) / Double(topic.questions.count)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                QuizArtwork(assetName: topic.artworkName, symbol: topic.symbol, tint: topic.tint, height: 102)
                    .frame(width: 108)
                    .clipShape(.rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(topic.title)
                            .font(.mimi(size: 20, weight: .heavy))
                            .foregroundStyle(MimiTheme.onSurface)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(topic.tint)
                    }

                    Text(topic.subtitle)
                        .font(.mimi(size: 13, weight: .medium))
                        .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    ProgressView(value: progress)
                        .tint(topic.tint)

                    HStack(spacing: 8) {
                        Label(L10n.text("%d/%d answered", answeredCount, topic.questions.count), systemImage: "checklist")
                        Label(L10n.text("%d right", correctCount), systemImage: "star.fill")
                    }
                    .font(.mimi(size: 11, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                }
            }
            .padding(14)
            .softCard(cornerRadius: 30)
        }
        .buttonStyle(.plain)
    }
}

private struct QuizSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MonetizationService.self) private var monetizationService
    let topic: QuizTopic
    let recordAnswer: (QuizQuestion, Int) -> Void
    @State private var questionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var correctAnswers = 0
    @State private var isFinished = false

    private var question: QuizQuestion {
        topic.questions[questionIndex]
    }

    private var progressText: String {
        L10n.text("Question %d of %d", questionIndex + 1, topic.questions.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MimiBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if isFinished {
                            QuizSessionSummary(
                                topic: topic,
                                correctAnswers: correctAnswers,
                                restartAction: restart,
                                doneAction: { dismiss() }
                            )
                        } else {
                            sessionContent
                        }
                    }
                    .padding(20)
                    .padding(.bottom, selectedAnswer == nil || isFinished ? 18 : 96)
                }
            }
            .navigationTitle(topic.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("Done")) { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedAnswer != nil, !isFinished {
                    sessionFooter
                }
            }
        }
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
    }

    private var sessionContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuizArtwork(assetName: topic.artworkName, symbol: topic.symbol, tint: topic.tint, height: 96)
                .clipShape(.rect(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(progressText)
                        .font(.mimi(size: 11, weight: .heavy))
                        .foregroundStyle(topic.tint)
                        .textCase(.uppercase)
                        .tracking(1)

                    Spacer()

                    Text(question.difficulty)
                        .font(.mimi(size: 11, weight: .bold))
                        .foregroundStyle(topic.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(topic.tint.opacity(0.10), in: .capsule)
                }

                ProgressView(value: Double(questionIndex + 1), total: Double(topic.questions.count))
                    .tint(topic.tint)

                Text(question.prompt)
                    .font(.mimi(size: 21, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(question.answers.indices, id: \.self) { index in
                        QuizAnswerButton(question: question, index: index, selectedAnswer: selectedAnswer) {
                            answerQuestion(index)
                        }
                        .disabled(selectedAnswer != nil)
                    }
                }

                if let selectedAnswer {
                    QuizFeedback(question: question, selectedAnswer: selectedAnswer)
                    .transition(.opacity)
                }
            }
            .padding(18)
            .softCard(cornerRadius: 32)
        }
    }

    private var sessionFooter: some View {
        Button(action: advance) {
            Label(
                questionIndex == topic.questions.count - 1 ? L10n.text("Finish quiz") : L10n.text("Next question"),
                systemImage: questionIndex == topic.questions.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill"
            )
            .font(.mimi(size: 15, weight: .heavy))
            .foregroundStyle(MimiTheme.primaryInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(MimiTheme.primary, in: .rect(cornerRadius: 22))
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .buttonStyle(.plain)
    }

    private func answerQuestion(_ answerIndex: Int) {
        selectedAnswer = answerIndex
        recordAnswer(question, answerIndex)

        if answerIndex == question.correctAnswerIndex {
            correctAnswers += 1
        }
    }

    private func advance() {
        if questionIndex == topic.questions.count - 1 {
            isFinished = true
            Task {
                await monetizationService.record(.quizCompleted)
            }
        } else {
            questionIndex += 1
            selectedAnswer = nil
        }
    }

    private func restart() {
        questionIndex = 0
        selectedAnswer = nil
        correctAnswers = 0
        isFinished = false
    }
}

private struct QuizSessionSummary: View {
    let topic: QuizTopic
    let correctAnswers: Int
    let restartAction: () -> Void
    let doneAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            QuizArtwork(assetName: "Quiz cat", symbol: "checkmark.seal.fill", tint: topic.tint, height: 160)
                .clipShape(.rect(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("Quiz complete"))
                    .font(.mimi(size: 12, weight: .heavy))
                    .foregroundStyle(topic.tint)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(L10n.text("%d of %d right", correctAnswers, topic.questions.count))
                    .font(.mimi(size: 32, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)

                Text(L10n.text("Nice work. Retake it anytime to sharpen the clues."))
                    .font(.mimi(size: 14, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(action: restartAction) {
                        Label(L10n.text("Practice again"), systemImage: "arrow.counterclockwise")
                            .font(.mimi(size: 14, weight: .heavy))
                            .foregroundStyle(topic.tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(topic.tint.opacity(0.10), in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)

                    Button(action: doneAction) {
                        Label(L10n.text("Done"), systemImage: "checkmark")
                            .font(.mimi(size: 14, weight: .heavy))
                            .foregroundStyle(MimiTheme.primaryInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(MimiTheme.primary, in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .softCard(cornerRadius: 32)
        }
    }
}

private struct QuizAnswerButton: View {
    let question: QuizQuestion
    let index: Int
    let selectedAnswer: Int?
    let action: () -> Void

    private var isSelected: Bool {
        selectedAnswer == index
    }

    private var isCorrectAnswer: Bool {
        question.correctAnswerIndex == index
    }

    private var tint: Color {
        guard selectedAnswer != nil else { return MimiTheme.onSurface }
        if isCorrectAnswer { return MimiTheme.success }
        if isSelected { return MimiTheme.error }
        return MimiTheme.onSurfaceVariant.opacity(0.72)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Text(question.answers[index])
                    .font(.mimi(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let selectedAnswer {
                    if isCorrectAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MimiTheme.success)
                    } else if selectedAnswer == index {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MimiTheme.error)
                    }
                }
            }
            .padding(16)
            .background(tint.opacity(selectedAnswer == nil ? 0.06 : 0.12), in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

private struct QuizFeedback: View {
    let question: QuizQuestion
    let selectedAnswer: Int

    private var isCorrect: Bool {
        selectedAnswer == question.correctAnswerIndex
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.seal.fill" : "lightbulb.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isCorrect ? MimiTheme.success : MimiTheme.primaryInk)
                .frame(width: 38, height: 38)
                .background((isCorrect ? MimiTheme.success : MimiTheme.primary).opacity(0.12), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? L10n.text("Correct") : L10n.text("Good clue to learn"))
                    .font(.mimi(size: 14, weight: .heavy))
                    .foregroundStyle(MimiTheme.onSurface)

                Text(question.explanation)
                    .font(.mimi(size: 13, weight: .bold))
                    .foregroundStyle(MimiTheme.onSurfaceVariant.opacity(0.82))
                    .lineLimit(3)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background((isCorrect ? MimiTheme.success : MimiTheme.primary).opacity(0.08), in: .rect(cornerRadius: 22))
    }
}
