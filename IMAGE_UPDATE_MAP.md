# Image Update Map

This file maps every current image slot, fallback, and icon/emoji placeholder that is relevant to replacing the app artwork.

## Onboarding And Paywall

| Slot | Screen / placement | Asset expected | Current fallback / placeholder | Asset status |
| --- | --- | --- | --- | --- |
| Welcome cat | Onboarding step 1, main artwork | `Onboarding Welcome Cat` | `Cat Mascot`, then `pawprint.fill` | Exists |
| Name cat | Onboarding name step, main artwork | `Onboarding Name Cat` | `Cat Mascot`, then `pawprint.fill` | Exists |
| Profile option 1 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 1` | `Cat Mascot`, then `pawprint.fill` | Missing |
| Profile option 2 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 2` | `Cat Mascot (4)`, then `Cat Mascot`, then `pawprint.fill` | Missing |
| Profile option 3 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 3` | `Cat Mascot (5)`, then `Cat Mascot`, then `pawprint.fill` | Missing |
| Profile option 4 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 4` | `Cat Mascot (6)`, then `Cat Mascot`, then `pawprint.fill` | Missing |
| Profile option 5 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 5` | `Meow cat 13, 2026 at 11_06_19 AM (1)`, then `Cat Mascot`, then `pawprint.fill` | Missing |
| Profile option 6 | Onboarding profile carousel + profile/home avatar uses | `Profile Cat 6` | `Meow cat 13, 2026 at 11_06_19 AM (2)`, then `Cat Mascot`, then `pawprint.fill` | Missing |
| Translate cat | Onboarding translate step, main artwork | `Onboarding Translate Cat` | `Cat Mascot (4)`, then `pawprint.fill` | Exists |
| Learn cat | Onboarding learn step, main artwork | `Onboarding Learn Cat` | `Cat Mascot`, then `pawprint.fill` | Exists |
| Sounds cat | Onboarding sounds step, main artwork | `Onboarding Sounds Cat` | `Cat Mascot`, then `pawprint.fill` | Exists |
| Quiz cat | Onboarding quiz step, main artwork | `Onboarding Quiz Cat` | `Cat Mascot`, then `pawprint.fill` | Missing |
| Notifications cat | Onboarding notifications step, main artwork | `Onboarding Bell Cat` | `Cat Mascot (5)`, then `pawprint.fill` | Missing |
| Paywall crown cat | Paywall top artwork | `Paywall Crown Cat` | `Cat Mascot (6)`, then `pawprint.fill` | Missing |

Code reference: `Mimi/Features/Onboarding/OnboardingView.swift`.

## Learn Academy Artwork

These images appear twice: the lesson card hero (`190pt` high) and the lesson detail hero (`220pt` high). If the asset is missing, the app displays `TopicVisual`, a gradient card with the SF Symbol listed below.

| Lesson | Asset expected | Current placeholder symbol | Asset status |
| --- | --- | --- | --- |
| Notice the signals before the sound | `Academy Behavior Signals` | `eye.fill` | Exists |
| Read tail language without guessing | `Academy Tail Language` | `arrow.up.and.down.circle.fill` | Missing |
| Understand slow blinks and gentle greetings | `Academy Slow Blink` | `eye.circle.fill` | Missing |
| Help a shy cat feel safer | `Academy Shy Cat Trust` | `shield.lefthalf.filled` | Missing |
| Make cat introductions less stressful | `Academy Cat Introductions` | `door.left.hand.open` | Missing |
| Build a calmer mealtime rhythm | `Academy Calm Mealtime` | `fork.knife` | Exists |
| Choose a better bowl and feeding spot | `Academy Better Feeding Spot` | `fork.knife.circle.fill` | Missing |
| Understand your cat's water habits | `Academy Water Habits` | `drop.fill` | Missing |
| Use treats without losing balance | `Academy Balanced Treats` | `star.fill` | Missing |
| Spot food competition between cats | `Academy Food Competition` | `person.2.fill` | Missing |
| Use play to learn their patterns | `Academy Play Patterns` | `sparkles` | Exists |
| Find your cat's favorite toy style | `Academy Favorite Toy Style` | `wand.and.stars` | Missing |
| Build an indoor hunting routine | `Academy Indoor Hunt Routine` | `scope` | Missing |
| Keep every play session safe | `Academy Safe Play` | `shield.checkered` | Missing |
| Help a senior cat enjoy play | `Academy Senior Cat Play` | `heart.circle.fill` | Missing |
| Know when a sound is truly unusual | `Academy Unusual Sounds` | `cross.case.fill` | Exists |
| Notice litter-box changes early | `Academy Litter Box Clues` | `square.grid.3x3.fill` | Missing |
| Recognize stress before it builds | `Academy Early Stress Clues` | `gauge.with.dots.needle.67percent` | Missing |
| Prepare for a calmer vet visit | `Academy Calm Vet Visit` | `stethoscope` | Missing |
| Build a weekly wellness check | `Academy Weekly Wellness Check` | `calendar.badge.checkmark` | Missing |

Code references: `Mimi/Features/Learn/LearnContent.swift`, `Mimi/Features/Learn/LearnView.swift`.

## Sounds Screen

The Sounds screen currently uses one profile companion image plus emoji placeholders inside each sound card. There is no asset field for sound cards yet; replacing these with images will need a small model/UI change, for example adding `artworkName` to `CatSound`.

| Slot | Screen / placement | Current placeholder | Suggested asset name |
| --- | --- | --- | --- |
| Header companion | Sounds header, right side of title | `Profile Cat 1` fallback chain | Use selected profile image or a dedicated `Sounds Header Cat` |
| Happy purr | Sound card leading 58x58 tile | `smiling cat emoji` | `Sound Happy Purr` |
| Dinner request | Sound card leading 58x58 tile | `plate emoji` | `Sound Dinner Request` |
| Love trill | Sound card leading 58x58 tile | `hearts emoji` | `Sound Love Trill` |
| Nap purr | Sound card leading 58x58 tile | `sleep emoji` | `Sound Nap Purr` |
| Morning meow | Sound card leading 58x58 tile | `sun emoji` | `Sound Morning Meow` |
| Play/pause action | Sound card trailing circular button | `play.fill` / `pause.fill` | Usually keep as icon unless you want custom button art |

Code reference: `Mimi/Features/Sounds/SoundsView.swift`.

## Quiz Screen

Quiz currently has no bitmap artwork. All hero visuals are `TopicVisual` gradient placeholders with SF Symbols.

| Slot | Screen / placement | Current placeholder symbol | Suggested asset name |
| --- | --- | --- | --- |
| Quiz overview | Top progress card, left hero | `questionmark.bubble.fill` | `Quiz Overview Cat` |
| Behavior quiz topic | Topic card image + quiz session hero | `eye.fill` | `Quiz Behavior` |
| Nutrition quiz topic | Topic card image + quiz session hero | `fork.knife` | `Quiz Nutrition` |
| Health quiz topic | Topic card image + quiz session hero | `cross.case.fill` | `Quiz Health` |
| Play quiz topic | Topic card image + quiz session hero | `sparkles` | `Quiz Play` |
| Quiz completion | Quiz summary top hero | `checkmark.seal.fill` | `Quiz Complete Cat` |
| Correct feedback | Inline feedback icon | `checkmark.seal.fill` | Usually keep as icon unless feedback cards get custom art |
| Learn feedback | Inline feedback icon | `lightbulb.fill` | Usually keep as icon unless feedback cards get custom art |

Code reference: `Mimi/Features/Quiz/QuizView.swift`.

## Tab Bar Icons

These are SF Symbols, not bitmap images. If you want custom tab art, these are the four slots to replace.

| Tab | Current symbol |
| --- | --- |
| Translate | `bubble.left.and.bubble.right.fill` |
| Learn | `book.pages.fill` |
| Sounds | `speaker.wave.3.fill` |
| Quiz | `questionmark.circle.fill` |

Code reference: `Mimi/Features/AppShell/AppTabView.swift`.

## Other Profile Image Placements

All of these use the selected `Profile Cat 1` through `Profile Cat 6` asset, with the same fallback chain listed in the onboarding profile rows.

| Placement | Size / usage |
| --- | --- |
| Home header avatar | `44pt` |
| Empty translate conversation state | `150pt` |
| Conversation message avatar | `34pt` |
| Profile screen main avatar | `180pt` |
| Profile screen avatar picker | `74pt` |
| Signal companion badge | `45%` of the companion size |

Code references: `Mimi/Features/Home/HomeView.swift`, `Mimi/Features/Profile/CatProfileView.swift`, `Mimi/Components/SignalCompanionView.swift`, `Mimi/Components/SharedComponents.swift`.

## Asset Catalog Cleanup Notes

Directly referenced image sets currently in use:

`Academy Behavior Signals`, `Academy Calm Mealtime`, `Academy Play Patterns`, `Academy Unusual Sounds`, `Cat Mascot`, `Cat Mascot (4)`, `Cat Mascot (5)`, `Cat Mascot (6)`, `Meow cat 13, 2026 at 11_06_19 AM (1)`, `Meow cat 13, 2026 at 11_06_19 AM (2)`, `Onboarding Learn Cat`, `Onboarding Name Cat`, `Onboarding Sounds Cat`, `Onboarding Translate Cat`, `Onboarding Welcome Cat`.

Image sets present in `Assets.xcassets` but not directly referenced by Swift code:

`ChatGPT Image Jun 13, 2026 at 11_15_42 AM`, `ChatGPT Image Jun 15, 2026 at 05_05_42 PM (5)`, `ChatGPT Image Jun 15, 2026 at 05_05_43 PM (7)`, `ChatGPT Image Jun 15, 2026 at 05_05_43 PM (8)`, `ChatGPT Image Jun 15, 2026 at 05_05_43 PM (9)`, `Meow cat 13, 2026 at 11_02_46 AM (1)`, `Meow cat 13, 2026 at 11_02_46 AM (2)`, `Meow cat 13, 2026 at 11_02_47 AM (3)`, `Meow cat 13, 2026 at 11_02_47 AM (4)`, `Meow cat 13, 2026 at 11_02_48 AM (5)`, `Meow cat 13, 2026 at 11_02_48 AM (6)`, `Meow cat 13, 2026 at 11_02_48 AM (7)`, `Meow cat 13, 2026 at 11_02_48 AM (8)`, `Meow cat 13, 2026 at 11_06_20 AM (3)`, `Meow cat 13, 2026 at 11_06_20 AM (4)`, `Meow cat 13, 2026 at 11_06_20 AM (5)`, `Meow cat 13, 2026 at 11_06_20 AM (6)`, `Meow cat 13, 2026 at 11_06_21 AM (7)`, `Meow cat 13, 2026 at 11_06_21 AM (8)`, `Meow cat 13, 2026 at 11_09_00 AM (1)`, `Meow cat 13, 2026 at 11_09_00 AM (2)`, `Meow cat 13, 2026 at 11_09_00 AM (3)`.
