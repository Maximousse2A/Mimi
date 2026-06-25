# Mimi translation content strategy

## Product promise

Mimi is an entertainment experience inspired by observable sound patterns. A result should feel like a tiny line of cat dialogue: short, charming, replayable, and easy to share. It must not imply that the app literally understands feline language or can diagnose health, pain, or intent.

## Editorial system

The library contains 120 lines across ten contextual families:

- hungry
- attention
- playful
- affection
- curious
- calm
- night
- morning
- evening
- repeated

Each family has four lines in each voice:

- Warm: affectionate, reassuring, cozy
- Playful: funny, theatrical, meme-friendly
- Direct: very short and immediately readable

Every headline should ideally remain under seven English words, fit in two lines on a compact iPhone, avoid medical claims, and sound natural when read as the cat's inner monologue.

## Selection rules

1. Sound quality, pattern, intensity, pauses, energy trend, approximate pitch, duration, and time of day choose a contextual family.
2. The profile's interpretation style chooses the preferred voice.
3. The last 12 displayed lines are excluded whenever another candidate is available.
4. Similar recordings no longer copy the previous result. They enter the repeated family and receive a fresh follow-up line.
5. Selection is deterministic from the recording signature, five-second time bucket, and history count. This creates variety without arbitrary UI rerenders changing the result.
6. When the four preferred-voice lines have recently appeared, selection expands to the other voices in the same contextual family.

## Content quality checklist

- Sounds like dialogue, not an analytics label.
- Understandable without opening the technical details.
- Fun to screenshot or read aloud.
- No shame, fear, death, illness, or veterinary diagnosis jokes.
- Food is framed as a playful possibility, never a factual conclusion.
- Urgent sounds request attention without claiming an emergency.
- French is adapted for tone and rhythm rather than translated word for word.

## Iteration metrics

Track these events by phrase key and contextual family:

- result shown
- detail expanded
- audio replayed
- result shared
- another recording started within 30 seconds
- session ended after result

Use replay, sharing, and immediate re-recording as positive entertainment signals. Retire lines with consistently weak engagement, and test new batches inside one family at a time so sound classification and copy quality remain distinguishable.
