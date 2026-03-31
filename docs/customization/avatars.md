# Avatars

Personalize your agent with chibi characters that express emotions through stickers.

## What It Does

Choose from 6 pre-built chibi characters, each with 8 emotion variants. Your avatar:

- Appears next to agent messages in the **chat UI**
- Changes expression based on **carousel position** in the settings UI

> **For everyone:** The avatar system makes interacting with the agent more personal and fun. It's like giving the AI a face that reacts to the conversation.

## Characters

| ID | Name | Personality |
|----|------|-------------|
| chibi-01 | Ezra | Calm, thoughtful |
| chibi-02 | Miriam | Energetic, cheerful |
| chibi-03 | Caleb | Bold, confident |
| chibi-04 | Esther | Graceful, wise |
| chibi-05 | Josiah | Determined, focused |
| chibi-06 | Naomi | Warm, nurturing |

## Emotion Variants

Each character has 8 expression variants:

| Emotion | When Used | Emoji Triggers |
|---------|----------|----------------|
| `neutral` | Default state | — |
| `happy` | Positive responses | 😊 😄 🙂 |
| `sad` | Error reports, bad news | 😢 😞 |
| `excited` | Success, achievements | 🎉 🚀 ✨ |
| `thinking` | Analysis, processing | 🤔 💭 |
| `surprised` | Unexpected findings | 😮 😲 |
| `smug` | Clever solutions | 😏 😎 |
| `pleading` | Soft confirmations | 🥺 🙏 |

## Animated Video Transitions

In addition to static stickers, supported avatars (like **Naomi / chibi-06**) use dynamically generated `.webm`/`.mp4` videos for fully animated emotion transitions. 

When the agent responds in the Chat View, the client-side emotion detection interceptor scans the text for specific emojis. If an emotion shift is detected (e.g., from `thinking` to `happy`), the UI seamlessly plays a video transition (generated via Google's Veo 3.1 frame interpolation) connecting the two states, making the AI feel genuinely responsive and alive.

## Carousel Expressions

In the Settings avatar carousel, expressions change based on position:

- **Center** → `happy`
- **±1 away** → `neutral`
- **±2 away** → `thinking`
- **Edge** → `surprised`
- **Hover** → `pleading`
- **Click** → `excited`

## Localized Names

Avatar names are translated in 8 languages (EN, DE, ES, FR, IT, PT, JA, KO).

You can also set a **custom name** for your avatar via Settings — this overrides the localized name.

## File Locations

Avatar assets are stored in:
```
packages/web/public/avatars/
├── chibi-01/
│   ├── neutral.png
│   ├── happy.png
│   ├── sad.png
│   ├── excited.png
│   ├── thinking.png
│   ├── surprised.png
│   ├── smug.png
│   └── pleading.png
├── chibi-02/
│   └── ...
└── ...
```
