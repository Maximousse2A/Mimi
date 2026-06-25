# Mimi

Mimi is an independently designed voice-interpretation concept built in SwiftUI
for iOS 26. Its visual identity uses abstract signal forms, warm editorial
typography, dimensional color, and native Liquid Glass controls.

## Onboarding artwork

Add image sets with these exact names to replace the fallback mascot:

- `Onboarding Welcome Cat` - a cat waving or saying hello
- `Onboarding Name Cat` - a cat waiting for their name
- `Onboarding Translate Cat` - a cat talking into a microphone
- `Onboarding Learn Cat` - a cat reading a tiny book
- `Onboarding Sounds Cat` - a cat wearing headphones
- `Onboarding Quiz Cat` - a cat proudly holding a quiz trophy
- `Onboarding Bell Cat` - a cat ringing a little bell
- `Paywall Crown Cat` - a cat proudly wearing a tiny crown

Use transparent PNGs without a baked checkerboard background.

Add profile image sets named `Profile Cat 1` through `Profile Cat 6`. Until
those are provided, the picker falls back to the existing cat artwork.
The selected profile image is also used for the large home-screen companion
under "What is Mimi trying to tell you?", so replacing `Profile Cat 1` is the
quick path for a custom mascot photo.

Mimi+ products are loaded from the current RevenueCat offering.

## V2 photo analysis

Photo analysis is hidden in the V1 app. The local Vision-backed implementation
remains in the codebase for a future V2 pass, but the current user-facing flow
is sound-only.
