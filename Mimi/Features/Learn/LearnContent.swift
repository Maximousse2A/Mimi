import SwiftUI

struct LearnTopic: Identifiable {
    let id: String
    let category: LearnCategory
    let title: String
    let subtitle: String
    let bigIdea: String
    let context: [String]
    let readTime: String
    let symbol: String
    let artworkName: String
    let tint: Color
    let sections: [LearnSection]
    let actionTitle: String
    let actions: [String]
    let note: LearnNote
}

struct LearnSection: Identifiable {
    let title: String
    let body: String
    let symbol: String

    var id: String { title }
}

struct LearnNote {
    let title: String
    let body: String
    let isSafetyNote: Bool
}

enum LearnCategory: String, CaseIterable, Identifiable {
    case all
    case behavior
    case nutrition
    case health
    case play

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .all:
            L10n.text("All")
        case .behavior:
            L10n.text("Behavior")
        case .nutrition:
            L10n.text("Nutrition")
        case .health:
            L10n.text("Health")
        case .play:
            L10n.text("Play")
        }
    }
}

extension LearnTopic {
    static let samples: [LearnTopic] = (0..<5).flatMap { index in
        [behaviorTopics[index], nutritionTopics[index], playTopics[index], healthTopics[index]]
    }

    private static let behaviorTopics = [
        article(
            id: "signals-before-sound", category: .behavior,
            title: "Notice the signals before the sound",
            subtitle: "Context turns a noise into useful information.",
            bigIdea: "A meow becomes meaningful when you pair it with body language, location, timing, and the change that happened just before it.",
            context: [
                "Cats rarely communicate with one channel at a time. A sound is usually layered on top of posture, distance, eye shape, tail movement, routine, and the nearby resource the cat cares about. The same short meow can mean greeting at the door, food expectation in the kitchen, frustration by a closed room, or worry beside a carrier.",
                "For humans, the useful habit is to slow the first reaction. Instead of answering every sound with food, petting, or correction, look for the pattern: what the cat did before the sound, what they do after it, and whether this is normal for them. That turns Mimi from a cute translator into a field notebook for the cat's real life."
            ],
            readTime: "10 min", symbol: "eye.fill", artworkName: "Academy Behavior Signals", tint: MimiTheme.primaryInk,
            sections: [
                idea("Start with the face", "Soft eyes, a relaxed mouth, and ears held forward or neutral usually belong to a settled moment. Sideways ears, a fixed stare, tense whiskers, or very wide pupils can mean excitement, fear, pain, or low light, so check the rest of the scene before deciding.", "face.smiling.inverse"),
                idea("Read posture and distance", "A loose cat may walk toward you, stretch, rub, or sit with paws tucked calmly. A worried cat often lowers the body, freezes, leans away, crouches near an exit, or tries to become smaller. If the body is saying distance, give distance before offering anything else.", "cat.fill"),
                idea("Attach the sound to a place", "A meow at the bowl is not the same as a meow at the litter box, the front door, the carrier, or a closed bedroom. Location tells you what the cat may be monitoring: food, territory, access, elimination, social contact, or a situation they want to avoid.", "mappin.and.ellipse"),
                idea("Ask what changed", "Many confusing sounds appear after a change humans barely notice: guests, a moved chair, a new detergent smell, a blocked window perch, a late meal, construction noise, or another pet near a doorway. Sudden changes from your cat's normal voice deserve extra attention.", "clock.arrow.circlepath"),
                idea("Choose the least pressuring answer", "The best first response is often simple: soften your body, open an exit, check water or litter, move a competing pet, or invite contact without insisting. If the sound repeats with hiding, appetite change, labored breathing, pain, or litter-box trouble, treat it as health information.", "hand.raised.fill")
            ],
            actionTitle: "Use the four-clue pause",
            actions: [
                "Pause before reacting and notice the sound without naming it yet.",
                "Scan face, body, location, and the event that happened just before it.",
                "Choose a low-pressure response: offer space, check a resource, or invite gentle contact.",
                "Save the pattern only after you see what your cat does next."
            ],
            note: note("One clue is never the whole story", "Body-language signals can mean different things in different cats and different rooms. Trust clusters of clues, repeated patterns, and changes from your own cat's baseline.")
        ),
        article(
            id: "tail-language", category: .behavior,
            title: "Read tail language without guessing",
            subtitle: "Movement, height, curve, and tension all add meaning.",
            bigIdea: "The tail is a useful arousal meter, but it only becomes meaningful when you read it with the cat's posture and the situation.",
            context: [
                "Humans tend to want a tail dictionary: up means happy, low means scared, swishing means angry. Real cats are messier and more interesting. Tail height, speed, stiffness, direction, and fur all change with arousal, and arousal can be social, playful, frustrated, fearful, or predatory.",
                "The goal is not to memorize a universal code. The goal is to learn how your cat's tail looks during greetings, hunting games, window watching, tense multi-cat moments, and overstimulation during petting. Once you know those patterns, you can stop sooner, give space earlier, and make home feel more predictable."
            ],
            readTime: "9 min", symbol: "arrow.up.and.down.circle.fill", artworkName: "Academy Tail Language", tint: MimiTheme.primaryInk,
            sections: [
                idea("Notice the greeting tail", "An upright tail, sometimes with a soft curve or little quiver, often appears when a cat approaches a familiar human or friendly cat. If the body is loose and the cat chooses contact, you can greet calmly and let them decide whether it becomes petting.", "arrow.up.circle.fill"),
                idea("Separate low from relaxed", "A tail carried low can be neutral during stalking or cautious movement, but tucked close under the body often points to fear or discomfort. Look for crouching, ears turned back, hiding, or quick escape routes before you reach in.", "arrow.down.circle.fill"),
                idea("Read the speed", "A slow tip twitch during bird watching or play can mean focus. A fast side-to-side lash during petting, brushing, or being held often means intensity is rising. Stop the interaction before the tail has to become a bite or scratch warning.", "speedometer"),
                idea("Respect a puffed tail", "Puffed fur makes the cat look larger. It can appear with fear, surprise, conflict, or defensive arousal. Lower noise, increase distance, block the scary view if needed, and avoid picking the cat up while they are in that state.", "exclamationmark.triangle.fill"),
                idea("Read tailless cats differently", "Cats with very short tails, stiff tails, or injuries still communicate through hips, back height, ears, eyes, whiskers, and movement. Do not assume a missing tail means missing emotion; just shift your attention to the rest of the body.", "eye.fill")
            ],
            actionTitle: "Build a tail dictionary",
            actions: [
                "Pick one familiar daily moment, such as greeting or play.",
                "Notice the tail's height, shape, and speed during that moment.",
                "Compare it with a different moment and save the pattern you see.",
                "Pair every tail note with the ears, posture, and what happened next."
            ],
            note: note("Avoid universal translations", "The same movement can carry different meaning across situations and individual cats. A tail note is strongest when it matches the face, body, and context.")
        ),
        article(
            id: "slow-blinks", category: .behavior,
            title: "Understand slow blinks and gentle greetings",
            subtitle: "Connection often happens quietly and at the cat's pace.",
            bigIdea: "A relaxed greeting gives your cat room to choose closeness instead of demanding it.",
            context: [
                "Slow blinking is one of the clearest examples of how subtle cat communication can be. Research suggests cats are more likely to narrow their eyes back at humans who slow blink, and may be more willing to approach after that kind of soft interaction. It is not a command; it is a low-pressure invitation.",
                "This matters because many human greetings are intense from a cat's point of view. We face them directly, lean over them, stare, speak loudly, and reach before they have agreed. A better greeting makes you smaller, softer, and easier to leave."
            ],
            readTime: "8 min", symbol: "eye.circle.fill", artworkName: "Academy Slow Blink", tint: MimiTheme.primaryInk,
            sections: [
                idea("Make your body less direct", "Turn slightly sideways, lower your shoulders, and avoid leaning over the cat. A person standing squarely above a cat can feel like pressure even when the intention is affectionate.", "figure.stand"),
                idea("Use the blink as an invitation", "Relax your face, narrow your eyes gently, close them for a brief moment, then look slightly away. If your cat blinks back, stays relaxed, or approaches, the greeting is going well.", "eye.fill"),
                idea("Offer a hand without chasing", "If the cat approaches, hold a relaxed hand low and still, then let them sniff or rub. A cheek rub is a stronger yes than a single sniff. If they move away, let the conversation end there.", "hand.point.up.left.fill"),
                idea("Teach guests the quiet hello", "Guests often want to win a cat over quickly. Ask them to sit, ignore the cat at first, blink softly, and let the cat approach in their own time. This protects shy cats from becoming the entertainment.", "person.2.fill"),
                idea("Know when not to use it", "Do not slow blink at a cat who is cornered, hissing, trying to escape, or visibly panicked and expect it to fix the moment. First restore distance, exits, and safety; communication works after pressure drops.", "shield.fill")
            ],
            actionTitle: "Offer a quiet hello",
            actions: [
                "Sit nearby at your cat's level without blocking an exit.",
                "Give one gentle slow blink and relax your gaze.",
                "Wait for your cat to choose the next move.",
                "Reward any calm choice by keeping the moment easy to leave."
            ],
            note: note("Consent builds trust", "A greeting does not need to become petting. Let closeness remain your cat's choice.")
        ),
        article(
            id: "shy-cat-trust", category: .behavior,
            title: "Help a shy cat feel safer",
            subtitle: "Trust grows through choice, distance, and repeatable safety.",
            bigIdea: "A shy cat becomes braver when they can control distance, retreat safely, and predict what happens next.",
            context: [
                "Hiding is not failure. For a shy, newly adopted, undersocialized, or overwhelmed cat, hiding is a coping tool that keeps the nervous system from tipping into panic. Pulling the cat out, blocking the hiding place, or forcing touch can make the room itself feel unsafe.",
                "The human job is to become predictable. Food arrives without a chase. The safe zone stays safe. Play and treats appear at a distance the cat can handle. Over days or weeks, comfort may show up as tiny changes: eating while you are in the room, grooming, blinking, stretching, or choosing a slightly closer resting spot."
            ],
            readTime: "10 min", symbol: "shield.lefthalf.filled", artworkName: "Academy Shy Cat Trust", tint: MimiTheme.primaryInk,
            sections: [
                idea("Protect the safe zone", "Give your cat a quiet hiding place and never pull them out. A safe retreat is part of progress because it lets the cat recover without needing to defend themselves.", "house.fill"),
                idea("Separate resources from social pressure", "Food, water, litter, scratchers, and resting places should be reachable without crossing busy walkways or passing a person, dog, or bold cat. A shy cat should not have to be brave just to meet basic needs.", "square.grid.2x2.fill"),
                idea("Lower the human intensity", "Sit sideways at a distance, keep your hands close to your body, speak softly, and let treats land near the cat rather than using them as bait to pull the cat toward you.", "arrow.down.right.and.arrow.up.left"),
                idea("Use play as a bridge", "A wand toy moved slowly at the edge of the safe zone can be less socially demanding than petting. If the cat watches, tracks, or taps once, that is participation. Stop before they retreat hard.", "wand.and.stars"),
                idea("Notice quiet signs of progress", "A shy cat may not leap into your lap. Progress can be eating in your presence, resting with eyes half closed, grooming, stretching, sniffing your hand, or walking through the room instead of running.", "chart.line.uptrend.xyaxis")
            ],
            actionTitle: "Create one safe ritual",
            actions: [
                "Choose a quiet time and sit several feet from the safe zone.",
                "Offer a treat or gentle toy movement without moving closer.",
                "End after a calm moment and repeat the same ritual tomorrow.",
                "Move closer only when your cat repeatedly stays loose at the current distance."
            ],
            note: note("Progress may look small", "Eating, grooming, blinking, or resting in your presence can all be meaningful signs of comfort.")
        ),
        article(
            id: "cat-introductions", category: .behavior,
            title: "Make cat introductions less stressful",
            subtitle: "Slow stages protect both cats from avoidable conflict.",
            bigIdea: "Successful introductions are built through scent, distance, and positive experiences before shared space.",
            context: [
                "Cats can form close social bonds, but they do not automatically accept every new cat as family. Many conflicts begin because humans rush from scent to face-to-face contact before either cat feels safe. A tense first meeting can become a memory that takes weeks to undo.",
                "Think in stages instead of dates. Some introductions take a few days, some take months, and some households need professional support. The cats decide the pace through their bodies: eating, exploring, playing, and resting tell you more than the calendar."
            ],
            readTime: "12 min", symbol: "door.left.hand.open", artworkName: "Academy Cat Introductions", tint: MimiTheme.primaryInk,
            sections: [
                idea("Begin with a complete base room", "The new cat needs food, water, litter, hiding, bedding, scratching, toys, and perches in a separate room. The resident cat needs their own resources protected too, so the arrival does not feel like instant competition.", "door.left.hand.closed"),
                idea("Trade information safely", "Swap bedding, rub cloths on cheeks, and let each cat investigate scent without seeing the other cat. Calm scent contact creates familiarity without the pressure of eye contact or chasing.", "arrow.left.arrow.right"),
                idea("Pair the other cat with good things", "Feed, play, or offer treats on opposite sides of a closed door or barrier, far enough that both cats can eat and disengage. The point is not to force friendship; it is to make the other cat predict ordinary good moments.", "plus.circle.fill"),
                idea("Read tension before it explodes", "Staring, blocking, stalking, freezing, tail lashing, hiding, or one cat leaving food can matter as much as hissing. Physical fights are late-stage information. The useful work is noticing pressure earlier.", "eye.fill"),
                idea("Go back a stage without drama", "If either cat stops eating, hides more, rushes the barrier, growls repeatedly, or cannot settle afterward, return to scent or distance work for a few days. Moving back is not failure; it is how introductions stay repairable.", "arrow.uturn.left.circle.fill")
            ],
            actionTitle: "Prepare the first stage",
            actions: [
                "Set up a complete separate room before the cats meet.",
                "Exchange one soft item carrying each cat's scent.",
                "Pair calm reactions with treats, play, or another positive experience.",
                "Advance only when both cats can relax at the current step."
            ],
            note: note("Slow down when tension rises", "If either cat stops eating, hides persistently, blocks resources, or repeatedly escalates, return to an easier stage and seek professional guidance when needed.")
        )
    ]

    private static let nutritionTopics = [
        article(
            id: "calmer-mealtime-rhythm", category: .nutrition,
            title: "Build a calmer mealtime rhythm",
            subtitle: "Routines make appetite, stress, and health changes easier to read.",
            bigIdea: "A consistent feeding rhythm creates a useful baseline, so genuine changes stand out sooner.",
            context: [
                "How a cat eats can tell you almost as much as how much they eat. A healthy routine shows interest, approach speed, chewing comfort, pace, interruptions, and what happens afterward. When those details are familiar, a real change is easier to spot before it becomes dramatic.",
                "Cats also carry hunting biology into the kitchen. Many prefer several small opportunities to eat instead of one stressful event where every cat, human, appliance, and dog is moving through the same space. A calmer mealtime is not just nicer; it gives the cat permission to eat without scanning for threats."
            ],
            readTime: "10 min", symbol: "fork.knife", artworkName: "Academy Calm Mealtime", tint: MimiTheme.primary,
            sections: [
                idea("Make meals predictable, not rigid", "Serve measured food in familiar windows of time. Predictability reduces uncertainty, but a routine should survive normal life: if dinner is late sometimes, your cat should still know the bowl, room, and human response are calm.", "calendar"),
                idea("Watch the approach", "A cat who usually trots in but now waits in the hallway, sniffs and leaves, or eats only when the room is empty is giving useful information. The first change may be interest, not the final amount in the bowl.", "figure.walk"),
                idea("Notice chewing and posture", "Dropping food, pawing at the mouth, chewing on one side, stretching awkwardly, or repeatedly backing away can point to discomfort, bowl preference, dental pain, nausea, stress, or competition. Track it instead of guessing once.", "eye.fill"),
                idea("Connect meals to the litter box", "Food and water changes often show up later as stool, urine, weight, or energy changes. A calmer feeding baseline helps you notice when appetite, thirst, vomiting, constipation, or urine output no longer match your cat's normal pattern.", "square.grid.3x3.fill"),
                idea("Protect multi-cat meals", "Two cats eating in the same room are not automatically comfortable. If one stares, hovers, finishes fast, or controls the doorway, increase distance, add a visual barrier, or feed in separate rooms.", "person.2.fill")
            ],
            actionTitle: "Take a three-meal snapshot",
            actions: [
                "Serve the usual measured portion and note the time.",
                "Notice interest, pace, and how much remains without hovering.",
                "Compare three meals for a pattern instead of judging one moment alone.",
                "Save appetite changes together with water, litter-box, vomiting, and energy notes."
            ],
            note: note("A sudden appetite change deserves attention", "Contact a veterinarian promptly if your cat stops eating or an appetite change arrives with vomiting, weakness, pain, or other worrying signs.", safety: true)
        ),
        article(
            id: "feeding-spot", category: .nutrition,
            title: "Choose a better bowl and feeding spot",
            subtitle: "Comfort around the bowl can shape the whole meal.",
            bigIdea: "The best feeding setup is clean, quiet, easy to access, and comfortable for your individual cat.",
            context: [
                "A feeding spot is not just a place to drop food. From a cat's point of view, it is a small territory where they decide whether they can lower their head, focus, and eat without being surprised. Loud appliances, busy traffic, a litter box nearby, or another animal watching can change the meal.",
                "Small physical details matter too. Some cats dislike deep narrow bowls, some are fine with them, and some seniors or cats with stiffness prefer less bending. Rather than buying every product, observe one real meal and change one variable at a time."
            ],
            readTime: "8 min", symbol: "fork.knife.circle.fill", artworkName: "Academy Better Feeding Spot", tint: MimiTheme.primary,
            sections: [
                idea("Watch body position", "Notice whether your cat can eat without crouching awkwardly, stretching, twisting, or repeatedly backing away. A comfortable cat should be able to settle into the meal rather than negotiate the bowl.", "figure.stand"),
                idea("Match the bowl to the cat", "A wide shallow dish can help some cats eat without pressing their whiskers against the sides. Other cats prefer a plate, a puzzle feeder, or their familiar bowl. Preference is evidence; marketing is not.", "circle.grid.3x3.fill"),
                idea("Reduce interruptions", "Choose a place away from loud appliances, busy walkways, dogs, children rushing past, and the litter box. Cats are more relaxed when they can eat without constantly checking behind them.", "speaker.slash.fill"),
                idea("Think about access and height", "Kittens, seniors, and cats with mobility changes may need a spot that is easy to reach and a bowl that does not require uncomfortable bending. Raised bowls help some cats, but the right height is the one your cat uses comfortably.", "arrow.up.and.down.circle.fill"),
                idea("Keep smells readable", "Wash bowls regularly, remove old food, and avoid heavily scented cleaners near the feeding area. Cats use smell to evaluate safety and freshness, so strong human scents can be more disruptive than we realize.", "sparkles")
            ],
            actionTitle: "Run a feeding-spot check",
            actions: [
                "Watch one full meal from a respectful distance.",
                "Notice interruptions, awkward posture, or repeated pauses.",
                "Change one part of the setup and compare the next meal.",
                "Keep the improvement that makes your cat approach, eat, and leave more calmly."
            ],
            note: note("Let preference guide you", "Some cats prefer a wide, shallow dish; others are comfortable with their current bowl. Observe before replacing everything.")
        ),
        article(
            id: "water-habits", category: .nutrition,
            title: "Understand your cat's water habits",
            subtitle: "Small observations make drinking changes easier to catch.",
            bigIdea: "Multiple appealing water options help you learn what your cat prefers and what normal drinking looks like.",
            context: [
                "Many caregivers only notice water when the bowl is empty or untouched, but drinking behavior is full of clues: where the cat drinks, whether they prefer fresh water, whether they paw at it, whether they drink after dry food, and how urine output changes over time.",
                "There is no single perfect water setup. Some cats love fountains, some prefer a still bowl, some avoid water placed beside food, and some drink from odd places because those spots feel safer or fresher. The goal is to offer appealing choices and notice sudden departures from normal."
            ],
            readTime: "9 min", symbol: "drop.fill", artworkName: "Academy Water Habits", tint: MimiTheme.primary,
            sections: [
                idea("Offer more than one option", "Place fresh water in a few quiet, accessible locations. In multi-cat homes, one guarded bowl can quietly limit access even when water is technically available.", "square.grid.2x2.fill"),
                idea("Separate water from pressure", "Try at least one water station away from food, litter, noisy appliances, and busy paths. A cat who avoids the kitchen bowl may drink more comfortably from a bedroom, hallway, or elevated surface.", "mappin.and.ellipse"),
                idea("Learn the preference", "Your cat may favor ceramic, stainless steel, a wide bowl, a fountain, a glass, or a specific room. Preference matters more than a one-size-fits-all rule, as long as the setup stays clean and safe.", "heart.fill"),
                idea("Use urine as a clue", "It is hard to measure every sip, but clumping litter can show whether urine volume is steady, increasing, or decreasing. Bigger or more frequent clumps can be just as useful to note as repeated trips to the bowl.", "chart.bar.fill"),
                idea("Treat sudden change seriously", "A clear increase or decrease in drinking, especially with appetite change, weight change, vomiting, lethargy, or litter-box changes, is health information worth sharing with a veterinarian.", "cross.case.fill")
            ],
            actionTitle: "Map the favorite water spot",
            actions: [
                "Refresh two water stations in different quiet locations.",
                "Observe which one your cat visits over the next few days.",
                "Note any sudden change from their usual drinking pattern.",
                "Pair water notes with urine clumps, appetite, weight, and energy."
            ],
            note: note("Drinking changes can be medical clues", "Contact your veterinarian if your cat suddenly drinks much more or less, or if the change appears with other symptoms.", safety: true)
        ),
        article(
            id: "balanced-treats", category: .nutrition,
            title: "Use treats without losing balance",
            subtitle: "Tiny rewards work best with a clear purpose.",
            bigIdea: "Treats are most useful when they support connection, training, or care without quietly replacing balanced meals.",
            context: [
                "Treats are powerful because they can change emotion. A tiny reward can make the carrier less suspicious, brushing less invasive, nail handling more predictable, or a shy greeting feel safer. Used randomly all day, the same treats can quietly blur appetite, weight, and motivation.",
                "The balance is simple: give treats a job, keep the amount visible, and protect the main diet. If a cat has a medical condition, food allergy, prescription diet, or weight plan, treats belong in the veterinary conversation rather than outside it."
            ],
            readTime: "8 min", symbol: "star.fill", artworkName: "Academy Balanced Treats", tint: MimiTheme.primary,
            sections: [
                idea("Give treats a job", "Use small rewards for carrier practice, grooming cooperation, calm greetings, medication routines, coming when called, or another behavior you want to make easier.", "checkmark.seal.fill"),
                idea("Keep portions visible", "Set aside the day's treats instead of reaching into the bag repeatedly. Tiny pieces can still feel rewarding, and seeing the total helps humans avoid accidental overfeeding.", "circle.grid.3x3.fill"),
                idea("Reward the right emotional state", "Treat before the cat panics, not after the struggle. For example, reward looking into the carrier, one paw inside, or calm sniffing before you ever close the door.", "heart.fill"),
                idea("Protect meal motivation", "If treats arrive constantly, regular food can become less interesting and appetite changes become harder to interpret. Treats should support the diet, not become the diet.", "shield.fill"),
                idea("Use safe, known foods", "Avoid experimenting with human foods when you are trying to build a routine. Use cat-safe treats your cat tolerates well, and introduce new foods slowly enough that stomach or skin reactions are easier to notice.", "leaf.fill")
            ],
            actionTitle: "Create a daily treat budget",
            actions: [
                "Choose a small container for today's treats.",
                "Break larger treats into smaller rewards when practical.",
                "Use them for one helpful routine instead of random extras.",
                "Track whether treats change appetite, stool, weight, or begging patterns."
            ],
            note: note("Ask before changing a medical diet", "If your cat has a health condition or prescription diet, check with your veterinarian before adding new treats.", safety: true)
        ),
        article(
            id: "food-competition", category: .nutrition,
            title: "Spot food competition between cats",
            subtitle: "Quiet pressure can be easy to miss.",
            bigIdea: "Cats do not need to fight openly for one cat to feel blocked, rushed, or unsafe around food.",
            context: [
                "Competition in cat homes is often silent. One cat can control a doorway, stare from across the room, finish first and hover, or simply make the other cat wait until night. Humans may see two bowls and assume fairness, while one cat experiences mealtime as surveillance.",
                "Food competition matters because it affects more than dinner. It can change weight, stress, litter-box behavior, relationships, and how safe each cat feels moving through the home. The fix is usually environmental before it is emotional: more distance, more routes, and resources that cannot be guarded by one body."
            ],
            readTime: "10 min", symbol: "person.2.fill", artworkName: "Academy Food Competition", tint: MimiTheme.primary,
            sections: [
                idea("Look for subtle blocking", "One cat may stare, hover, sit in a doorway, claim the high spot, or approach the other bowl slowly enough that no fight happens. If another cat hesitates, leaves, or waits, pressure is present.", "eye.fill"),
                idea("Notice different eating speeds", "A cat that eats very quickly may be anticipating competition. A cat that eats only after everyone leaves may not be picky; they may be waiting for the room to become safe.", "speedometer"),
                idea("Map the escape routes", "A bowl in a corner can trap a cat between food and another animal. Place feeding stations where each cat can enter and leave without passing the other cat's face.", "arrow.left.and.right"),
                idea("Separate by sight, not just inches", "Two bowls six feet apart in the same open kitchen may still feel like one shared resource. Visual barriers, different levels, or separate rooms can help each cat stop monitoring the other.", "rectangle.split.2x1.fill"),
                idea("Watch the after-meal mood", "Competition may show up after eating as chasing, vomiting from rushing, hiding, grooming, or guarding the kitchen. A calm meal should end with ordinary movement, not a household reset.", "moon.fill")
            ],
            actionTitle: "Observe one shared mealtime",
            actions: [
                "Watch from a distance without changing the normal routine.",
                "Notice staring, hovering, blocking, rushing, or waiting.",
                "Move bowls farther apart or feed separately and compare.",
                "Keep the setup that lets each cat eat at a natural pace."
            ],
            note: note("Every cat needs reliable access", "Contact your veterinarian if a cat is losing weight, regularly missing meals, or showing a marked appetite change.", safety: true)
        )
    ]

    private static let playTopics = [
        article(
            id: "play-patterns", category: .play,
            title: "Use play to learn their patterns",
            subtitle: "Short sessions reveal energy, mood, confidence, and preference.",
            bigIdea: "Good play follows a cat's natural hunt rhythm and lets them choose how intensely to join.",
            context: [
                "Play is not just entertainment. For cats, it is a safe version of hunting: noticing, stalking, chasing, pouncing, catching, and recovering. When that sequence is available, indoor life becomes more interesting and frustration has somewhere healthy to go.",
                "Play is also a diagnostic window into ordinary wellbeing. A cat who usually stalks low but suddenly watches without moving, quits early, avoids jumping, or becomes rough faster than usual may be telling you about stress, pain, boredom, competition, or a routine that no longer fits."
            ],
            readTime: "10 min", symbol: "sparkles", artworkName: "Academy Play Patterns", tint: MimiTheme.tertiary,
            sections: [
                idea("Invite instead of demanding", "Start with small movements at a distance and let your cat notice. A cat who watches with focused eyes is already participating. Do not wave the toy in their face or force speed before interest appears.", "hand.raised.fill"),
                idea("Match the movement", "Some cats love prey that darts along baseboards; others prefer fluttering, hiding, rustling, or slow injured-prey motion. Change speed, height, and direction, then notice what earns the most focus.", "arrow.trianglehead.branch"),
                idea("Let the hunt complete", "Move through stalk, chase, pounce, and catch. Regular catches keep the game rewarding instead of turning it into endless frustration. If you use a laser, finish on a toy or treat the cat can actually catch.", "scope"),
                idea("Read arousal as it rises", "Fast tail lashes, skin ripples, pinned ears, grabbing hands, or frantic biting can mean the game is too intense or has gone too long. Slow the toy, offer a catch, or end before excitement spills into roughness.", "gauge.with.dots.needle.67percent"),
                idea("Use play as a daily note", "Track when your cat wants to play, what style works, how long they engage, and how they move. A change in play can reveal stress, stiffness, weight change, or conflict before other signs are obvious.", "note.text")
            ],
            actionTitle: "Run a five-minute play test",
            actions: [
                "Offer one toy and try low, high, fast, and hiding movements.",
                "Repeat the movement your cat follows most and allow several catches.",
                "End calmly, put string-like toys away, and note the winning movement for next time.",
                "Compare tomorrow's interest before assuming a toy is permanently boring."
            ],
            note: note("Keep hands out of the game", "Use toys rather than fingers or feet, and supervise toys with strings or small pieces.")
        ),
        article(
            id: "favorite-toy-style", category: .play,
            title: "Find your cat's favorite toy style",
            subtitle: "The movement matters more than the price tag.",
            bigIdea: "Toy preference often comes down to how something moves, sounds, hides, and feels when caught.",
            context: [
                "A cat does not know whether a toy is expensive. They know whether it behaves like something worth hunting. The same cat may ignore a feather waved overhead but become intensely focused when that feather disappears behind a chair leg.",
                "Toy preference is also personal. Age, confidence, body condition, past experiences, time of day, hunger, and household noise all shape what works. Testing styles gives you a vocabulary for your cat instead of a drawer full of rejected toys."
            ],
            readTime: "9 min", symbol: "wand.and.stars", artworkName: "Academy Favorite Toy Style", tint: MimiTheme.tertiary,
            sections: [
                idea("Try ground movement", "Slide or dart a toy along the floor, pause beside furniture, and disappear around corners to imitate small ground prey. Many cats prefer the chase to start low and partly hidden.", "arrow.left.and.right"),
                idea("Try air movement", "Use gentle fluttering and short landings rather than keeping a toy constantly out of reach. Birds land, stumble, pause, and change direction; endless overhead waving can become frustrating.", "wind"),
                idea("Try hidden movement", "Move a toy under paper, behind a pillow, or through a tunnel so sound and partial visibility invite investigation. For cautious cats, hidden movement can feel safer than direct pursuit.", "eye.slash.fill"),
                idea("Try sound and texture", "Some cats respond to crinkle, rattle, fleece, fur-like texture, cardboard, or the sound of a toy scraping lightly along the floor. Others dislike noise. Let attention and body softness guide you.", "speaker.wave.2.fill"),
                idea("Try solo and shared play", "A cat may enjoy batting a small toy alone but prefer wand play with you at night. Leave safe solo toys available, and reserve interactive toys for supervised sessions so they stay special and safe.", "person.fill")
            ],
            actionTitle: "Hold a three-style toy test",
            actions: [
                "Offer ground, air, and hidden movement for about a minute each.",
                "Notice stalking, focused eyes, pouncing, and return interest.",
                "Save the winning style and rotate toys to keep it fresh.",
                "Retest on a different day before deciding a style does not work."
            ],
            note: note("Interest can change by day", "A toy that is ignored today may work tomorrow. Time of day and energy level shape play too.")
        ),
        article(
            id: "indoor-hunt-routine", category: .play,
            title: "Build an indoor hunting routine",
            subtitle: "A little challenge can make home life richer.",
            bigIdea: "Short chances to search, chase, catch, and solve problems turn ordinary rooms into useful enrichment.",
            context: [
                "Indoor cats can live excellent lives, but the home has to offer more than food and a sofa. In nature-inspired terms, cats need chances to scan, stalk, climb, hide, scratch, solve, and rest in safe places. Without those outlets, energy can become night activity, attention-seeking, conflict, or boredom.",
                "An indoor hunt routine does not need a large home or expensive equipment. Corners, cardboard, food puzzles, safe perches, paper, and a human who moves a toy like prey can turn one room into a changing landscape."
            ],
            readTime: "10 min", symbol: "scope", artworkName: "Academy Indoor Hunt Routine", tint: MimiTheme.tertiary,
            sections: [
                idea("Use the room like terrain", "Corners, boxes, tunnels, rugs, chair legs, and safe furniture edges make movement less predictable. Prey that disappears and reappears is usually more interesting than prey dragged in a straight line.", "square.grid.3x3.fill"),
                idea("Add simple searching", "Hide a toy, a few pieces of kibble, or part of a meal where your cat can discover it without frustration. Searching should feel like a win, not a puzzle designed to prove a point.", "magnifyingglass"),
                idea("Include vertical choices", "Perches, cat trees, shelves, or a stable chair let cats survey the route and choose height. Vertical space can also reduce conflict because cats are not forced to share the same floor path.", "arrow.up.circle.fill"),
                idea("End with a real finish", "After stalking and chasing, let the cat catch the toy and then offer a small food reward or the next scheduled meal. This closes the hunt sequence and often makes the end calmer.", "checkmark.seal.fill"),
                idea("Rotate the challenge", "Change one detail at a time: the route, the hiding spot, the toy, or the time of day. Too much novelty can overwhelm some cats; small changes keep the game readable.", "repeat")
            ],
            actionTitle: "Create a ten-minute hunt",
            actions: [
                "Choose a safe route through two or three parts of one room.",
                "Guide a toy through stalk, chase, and several catches.",
                "Finish with a small food reward or the next scheduled meal.",
                "Make the next session easier or harder based on your cat's confidence."
            ],
            note: note("Success keeps enrichment fun", "If your cat walks away or becomes frustrated, make the next round shorter and easier.")
        ),
        article(
            id: "safe-play", category: .play,
            title: "Keep every play session safe",
            subtitle: "Good play ends with the toy, cat, and room intact.",
            bigIdea: "Safe play matches your cat's body, protects against swallowing hazards, and avoids risky jumps or collisions.",
            context: [
                "The best play is exciting but not reckless. Cats can accelerate, twist, and leap quickly, which means slippery floors, clutter, high furniture edges, string, and tiny detachable toy parts matter more than they seem during a fun moment.",
                "Safety is not about making play dull. It is about letting the cat use their body well, catch often, and finish without swallowing hazards, crashing into furniture, or practicing attacks on human hands."
            ],
            readTime: "9 min", symbol: "shield.checkered", artworkName: "Academy Safe Play", tint: MimiTheme.tertiary,
            sections: [
                idea("Inspect the toy", "Check for loose pieces, frayed strings, sharp edges, bells, glued eyes, feathers coming apart, or damage before and after play. A toy that looks funny to a human may look swallowable to a cat.", "magnifyingglass"),
                idea("Guide safe movement", "Avoid forcing sudden twists, very high jumps, or sprints across slippery floors and clutter. Let the toy travel through routes where the cat can grip, turn, land, and stop.", "figure.walk"),
                idea("Protect hands and feet", "Using fingers under blankets or toes as prey teaches the cat that human skin is part of the game. Redirect to a toy before roughness starts, especially with kittens who are learning bite control.", "hand.raised.fill"),
                idea("Use lasers carefully", "Lasers can create chase without catch. If you use one, keep movements low and controlled, avoid shining it at eyes, and end on a physical toy or treat the cat can actually capture.", "smallcircle.filled.circle.fill"),
                idea("Store risky toys", "Put away string, ribbon, elastic, yarn, tinsel, and toys with small detachable pieces when play is over. Supervised toys are not the same as leave-out toys.", "shippingbox.fill")
            ],
            actionTitle: "Do a sixty-second safety sweep",
            actions: [
                "Inspect the toy and clear the play route.",
                "Match speed and jumps to your cat's comfort and mobility.",
                "Count and store every loose or string-like toy afterward.",
                "End with a catch so the session closes before frustration or roughness builds."
            ],
            note: note("Swallowed objects can be urgent", "Contact a veterinarian promptly if you think your cat swallowed string, ribbon, a toy piece, or another foreign object.", safety: true)
        ),
        article(
            id: "senior-cat-play", category: .play,
            title: "Help a senior cat enjoy play",
            subtitle: "Play can stay joyful as movement changes.",
            bigIdea: "Senior-friendly play keeps the fun while adjusting speed, height, surface, and session length.",
            context: [
                "Older cats still need pleasure, novelty, and chances to use their hunting brain. What changes is the invitation. A senior cat may prefer shorter sessions, slower prey, stable footing, warm resting spots nearby, and games that reward watching, reaching, and catching without demanding athletic jumps.",
                "Because cats often hide pain, a drop in play should not be dismissed as laziness. Reluctance to jump, stiffness after rest, missed landings, irritability when touched, or avoiding favorite places can all be worth discussing with a veterinarian."
            ],
            readTime: "9 min", symbol: "heart.circle.fill", artworkName: "Academy Senior Cat Play", tint: MimiTheme.tertiary,
            sections: [
                idea("Keep movement reachable", "Use slower toys near the floor and let the game come to your cat instead of demanding long chases. A good senior game often happens within one comfortable body length.", "arrow.down.to.line"),
                idea("Choose comfortable footing", "Play on rugs or other stable surfaces and avoid routes that require difficult jumps, slippery turns, or hard landings. Add steps or ramps to favorite places if climbing has become harder.", "square.fill"),
                idea("Shorten the session", "Two minutes of engaged tracking may be better than ten minutes of fatigue. Stop while the cat is still interested, then offer rest, warmth, or the next calm part of the routine.", "timer"),
                idea("Value small engagement", "Watching, tracking, sniffing, pawing, and one short pounce can all be successful play. The goal is enjoyment and mental stimulation, not proving that your cat can still perform like a kitten.", "checkmark.circle.fill"),
                idea("Treat mobility changes as information", "New stiffness, hiding after play, reluctance to jump, weakness, or irritability can signal discomfort. Adjust the game immediately and bring the pattern to your veterinarian.", "cross.case.fill")
            ],
            actionTitle: "Try a gentle play minute",
            actions: [
                "Choose a familiar toy and a stable, comfortable surface.",
                "Move it slowly within easy reach and allow frequent catches.",
                "Stop before your cat tires and note what they enjoyed.",
                "Track any movement change that repeats across several days."
            ],
            note: note("Movement changes deserve attention", "Ask your veterinarian about new stiffness, reluctance to jump, weakness, pain, or a sudden drop in activity.", safety: true)
        )
    ]

    private static let healthTopics = [
        article(
            id: "unusual-sounds", category: .health,
            title: "Know when a sound is truly unusual",
            subtitle: "Changes matter more than any single vocalization.",
            bigIdea: "The most useful health clue is a clear change from your cat's normal sound, behavior, or routine.",
            context: [
                "Cats can become more vocal for many reasons: attention, learned routines, anxiety, hearing changes, age-related confusion, pain, high blood pressure, thyroid disease, conflict, or a resource problem they cannot solve. The sound alone rarely tells the whole story.",
                "A sound becomes more medically useful when it is tied to a timeline and companion signs. When did it start? Is it louder, rougher, more frequent, or happening at night? Does it come with appetite, water, litter-box, breathing, movement, weight, or social changes? That is the kind of information a veterinarian can actually use."
            ],
            readTime: "11 min", symbol: "cross.case.fill", artworkName: "Academy Unusual Sounds", tint: MimiTheme.success,
            sections: [
                idea("Know the baseline", "Notice your cat's usual frequency, pitch, volume, and common situations. A chatty cat becoming quiet can matter as much as a quiet cat suddenly howling.", "waveform.path"),
                idea("Separate request from distress", "A familiar meow at the food cupboard is different from repeated crying while crouched, hiding, straining, limping, or breathing oddly. The action after the sound often tells you more than the sound itself.", "ear.fill"),
                idea("Look for companion changes", "Pay attention to appetite, drinking, litter-box use, breathing, movement, hiding, grooming, sleep, weight, and willingness to interact. A cluster of changes deserves more attention than an isolated odd noise.", "checklist"),
                idea("Watch nighttime changes", "New night vocalization in an older cat can be related to routine, orientation, hearing, anxiety, pain, blood pressure, thyroid disease, or other health concerns. Do not assume it is just attention-seeking if it is new.", "moon.fill"),
                idea("Capture useful context", "A short video and notes about when, where, duration, posture, and what happened before and after can help a veterinarian understand a sound that may not appear during an appointment.", "video.fill")
            ],
            actionTitle: "Make a clear observation note",
            actions: [
                "Write down when the change began and how often it happens.",
                "Record the sound if you can do so without delaying care or stressing your cat.",
                "Add any changes in eating, litter-box use, breathing, movement, or behavior.",
                "Share the pattern with your veterinarian when the change is sudden, repeated, or worrying."
            ],
            note: note("Know the urgent signs", "Seek urgent veterinary care for trouble breathing, collapse, seizures, severe injury, or repeated straining with little or no urine. Mimi can organize observations, but it cannot diagnose illness.", safety: true)
        ),
        article(
            id: "litter-box-clues", category: .health,
            title: "Notice litter-box changes early",
            subtitle: "The litter box can reveal important changes before a cat looks sick.",
            bigIdea: "Changes in frequency, amount, posture, location, or comfort can be more useful than the occasional accident alone.",
            context: [
                "The litter box is one of the best daily health dashboards in a cat home. It shows urine amount, stool quality, frequency, comfort, mobility, and whether the environment feels safe enough to use. Because cats often hide illness, box changes may appear before obvious sickness.",
                "Humans often focus on accidents, but the earlier clues are usually smaller: more trips, smaller clumps, unusually large clumps, crying, digging without output, rushing away, missing the edge, stool changes, or a cat choosing a new location because the current route or box feels difficult."
            ],
            readTime: "11 min", symbol: "square.grid.3x3.fill", artworkName: "Academy Litter Box Clues", tint: MimiTheme.success,
            sections: [
                idea("Learn the normal pattern", "Notice the usual number and size of urine clumps, bowel movements, and how comfortably your cat enters and leaves. Normal is your cat's pattern, not an average from the internet.", "chart.bar.fill"),
                idea("Watch the posture", "Repeated trips, straining, crying, squatting without output, rushing away, or spending unusually long in the box are important observations. Little or no urine with repeated straining can be an emergency.", "eye.fill"),
                idea("Read stool changes too", "Hard dry stool, diarrhea, mucus, blood, very strong changes in odor, or a cat skipping their usual bowel movement pattern can be worth recording and discussing, especially if appetite or energy changes too.", "list.bullet.clipboard"),
                idea("Keep access easy", "Clean, accessible boxes in calm locations make normal use easier and changes more visible. Seniors and kittens may need lower sides, nearby boxes, and routes that do not require difficult stairs or guarded hallways.", "door.left.hand.open"),
                idea("Think beyond the box", "Avoiding the box can involve pain, urinary disease, constipation, stress, conflict, box size, litter texture, cleanliness, or location. Punishment only adds stress; observation and veterinary input are more useful.", "magnifyingglass")
            ],
            actionTitle: "Start a simple box baseline",
            actions: [
                "Scoop at a consistent time and notice the usual output.",
                "Watch for changes in frequency, amount, posture, or location.",
                "Record a clear change and contact your veterinarian when concerned.",
                "Treat repeated straining with little or no urine as urgent."
            ],
            note: note("Straining can be an emergency", "Seek urgent veterinary care if your cat repeatedly strains with little or no urine, especially with pain, crying, vomiting, or weakness.", safety: true)
        ),
        article(
            id: "early-stress-clues", category: .health,
            title: "Recognize stress before it builds",
            subtitle: "Small behavior changes can appear before obvious distress.",
            bigIdea: "Stress often shows up as a cluster of subtle changes in posture, routine, appetite, play, grooming, or social behavior.",
            context: [
                "Stress in cats is often quiet before it is dramatic. A cat may stop using a room, groom more, sleep somewhere new, avoid a pathway, eat only at night, reduce play, stare at another cat, or spend more time under furniture. By the time hissing or house-soiling appears, the pressure may have been building for a while.",
                "The humane response is to reduce pressure and investigate causes instead of labeling the cat stubborn or spiteful. Cats react to what feels unsafe, unrewarding, painful, or unpredictable. Their behavior is information about the environment and the body."
            ],
            readTime: "10 min", symbol: "gauge.with.dots.needle.67percent", artworkName: "Academy Early Stress Clues", tint: MimiTheme.success,
            sections: [
                idea("Look for shrinking behavior", "More hiding, crouching, freezing, avoiding rooms, moving low to the floor, or reduced interaction may signal that something feels difficult. The cat is not being antisocial; they are lowering exposure.", "arrow.down.right.and.arrow.up.left"),
                idea("Notice routine changes", "Changes in eating, grooming, sleep, play, scratching, window watching, or litter-box use can appear alongside stress. A routine change that repeats is worth logging even if it seems small.", "calendar.badge.exclamationmark"),
                idea("Find the pressure point", "Visitors, noise, construction, schedule changes, outdoor cats at windows, new smells, conflict, blocked routes, or missing resources can all affect comfort. Start with what changed before the behavior changed.", "magnifyingglass"),
                idea("Increase control and choice", "Add safe hiding, vertical space, separate food and water, multiple litter boxes, scratching options, and calm routes through the home. A cat who can choose distance often needs less defensive behavior.", "slider.horizontal.3"),
                idea("Change one variable at a time", "If you move every bowl, add every product, and change the whole schedule at once, you will not know what helped. Make one kind adjustment, observe for a few days, then keep building.", "1.circle.fill")
            ],
            actionTitle: "Lower one source of pressure",
            actions: [
                "List what changed shortly before the new behavior began.",
                "Restore one predictable routine or add a quiet safe space.",
                "Track whether the behavior improves over the next few days.",
                "Call your veterinarian if the change is sudden, severe, painful, or persistent."
            ],
            note: note("Behavior changes can have medical causes", "Contact your veterinarian when a change is sudden, persistent, severe, or accompanied by physical symptoms.", safety: true)
        ),
        article(
            id: "calm-vet-visit", category: .health,
            title: "Prepare for a calmer vet visit",
            subtitle: "The appointment starts long before the carrier closes.",
            bigIdea: "Carrier familiarity, useful notes, and a calm departure can make veterinary care easier for everyone.",
            context: [
                "For many cats, the hardest part of veterinary care is not the exam; it is the sudden appearance of the carrier, the chase, the car, unfamiliar smells, and loss of control. If the carrier only appears before stressful events, it becomes a warning sign.",
                "A calmer visit starts at home with familiarity and information. The carrier becomes ordinary furniture, the cat practices tiny steps without being trapped, and the human brings clear notes, videos, food details, medications, and questions so the clinic can work with the real pattern."
            ],
            readTime: "10 min", symbol: "stethoscope", artworkName: "Academy Calm Vet Visit", tint: MimiTheme.success,
            sections: [
                idea("Make the carrier ordinary", "Leave it open in a familiar room with soft bedding and occasional treats so it is not only a signal that something scary is coming. Let the cat enter and leave without the door closing at first.", "shippingbox.fill"),
                idea("Practice tiny steps", "Reward looking at the carrier, sniffing it, stepping inside, resting inside, then brief door movement later. Each easy repetition teaches that the carrier does not always predict a struggle.", "pawprint.fill"),
                idea("Bring the pattern", "Write down changes, timing, medications, food, treats, litter-box notes, and questions. Photos or short videos can show limping, coughing, vocalizing, or behavior that may not appear in the clinic.", "note.text"),
                idea("Plan the departure", "Prepare supplies early, keep your own movement calm, close doors to unsafe hiding areas before the final moment if needed, and avoid turning the visit into a last-minute chase.", "clock.fill"),
                idea("Ask for cat-friendly support", "Tell the clinic if your cat is fearful, painful, hard to handle, or stressed by dogs and waiting rooms. The team may suggest timing, handling, medication, or arrival options that reduce stress.", "phone.fill")
            ],
            actionTitle: "Start carrier practice today",
            actions: [
                "Place the open carrier in a comfortable everyday location.",
                "Add familiar bedding and reward voluntary exploration.",
                "Practice briefly closing and reopening it only after your cat is comfortable.",
                "Keep a short health note ready so visits are about useful information, not memory."
            ],
            note: note("Ask the clinic for help", "Your veterinary team can suggest visit preparation and transport options tailored to your cat's needs.")
        ),
        article(
            id: "weekly-wellness-check", category: .health,
            title: "Build a weekly wellness check",
            subtitle: "A familiar routine helps small changes stand out.",
            bigIdea: "A gentle weekly observation creates a baseline without trying to replace a veterinary examination.",
            context: [
                "The most useful health habit is knowing what normal looks like for your own cat. Normal includes appetite, water, litter-box output, sleep spots, play style, grooming, movement, weight, breathing, social behavior, and the small rituals your cat repeats every week.",
                "A wellness check should feel like ordinary life, not a forced exam. Use moments your cat already accepts: greeting, brushing, play, lap time, feeding, or scooping. You are not diagnosing; you are noticing patterns early enough to ask better questions."
            ],
            readTime: "10 min", symbol: "calendar.badge.checkmark", artworkName: "Academy Weekly Wellness Check", tint: MimiTheme.success,
            sections: [
                idea("Observe everyday function", "Notice appetite, drinking, litter-box habits, breathing, movement, grooming, play, sleep, and social behavior. The question is not perfect health; it is whether the pattern changed.", "checklist"),
                idea("Use gentle contact", "During normal affection, notice new sensitivity, swelling, matting, dandruff, odor, or coat changes without forcing an examination. Stop if your cat tenses, leaves, or objects.", "hand.raised.fill"),
                idea("Watch movement in real life", "Look at stairs, jumps, landings, getting into the litter box, turning around, and rising after rest. Mobility changes are easier to see in daily routes than during a staged check.", "figure.walk"),
                idea("Track weight with humility", "Weight gain and slow weight loss can both be hard to see under fur. Use photos, body shape, how collars or harnesses fit, and veterinary weigh-ins rather than relying only on memory.", "scalemass.fill"),
                idea("Keep useful notes", "Brief notes, photos, or videos can reveal trends and make veterinary conversations more specific. A clear timeline often matters more than a perfect description.", "note.text")
            ],
            actionTitle: "Create a five-minute check-in",
            actions: [
                "Choose the same calm day and time each week.",
                "Observe routine, movement, coat, and comfortable interaction.",
                "Record only meaningful changes and follow up when concerned.",
                "Bring repeated changes, even subtle ones, to your veterinarian."
            ],
            note: note("Wellness care is still veterinary care", "Keep regular veterinary appointments and contact your veterinarian sooner for sudden, persistent, or worrying changes.", safety: true)
        )
    ]

    private static func article(
        id: String,
        category: LearnCategory,
        title: String,
        subtitle: String,
        bigIdea: String,
        context: [String],
        readTime: String,
        symbol: String,
        artworkName: String,
        tint: Color,
        sections: [LearnSection],
        actionTitle: String,
        actions: [String],
        note: LearnNote
    ) -> LearnTopic {
        LearnTopic(
            id: id,
            category: category,
            title: L10n.text(title),
            subtitle: L10n.text(subtitle),
            bigIdea: L10n.text(bigIdea),
            context: context.map { L10n.text($0) },
            readTime: L10n.text(readTime),
            symbol: symbol,
            artworkName: artworkName,
            tint: tint,
            sections: sections,
            actionTitle: L10n.text(actionTitle),
            actions: actions.map { L10n.text($0) },
            note: note
        )
    }

    private static func idea(_ title: String, _ body: String, _ symbol: String) -> LearnSection {
        LearnSection(title: L10n.text(title), body: L10n.text(body), symbol: symbol)
    }

    private static func note(_ title: String, _ body: String, safety: Bool = false) -> LearnNote {
        LearnNote(title: L10n.text(title), body: L10n.text(body), isSafetyNote: safety)
    }
}
