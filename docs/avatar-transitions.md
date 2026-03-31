# Avatar Expression Transitions

The avatar system uses **position-based expressions** in the carousel and **video transitions** in the Agent Builder for animated expression changes.

## Video Transition State Machine

The `AvatarSphere.vue` component uses a 4-phase state machine when `interactive` mode is enabled. Every emotion change always routes through the **idle (neutral)** state.

### States

| Phase | Display | User Click |
|---|---|---|
| **idle** | `neutral_idle.mp4` looping | → `transition-out` to target emotion |
| **transition-out** | `neutral_to_X.mp4` playing (1.0×) | ignored (locked) |
| **emotion-hold** | `X.png` static image | → `transition-back` then chain to next |
| **transition-back** | `X_to_neutral.mp4` playing (1.6×) | ignored (locked) |

### Diagram

```
                    ┌──────────────────────┐
                    │     IDLE             │
                    │  neutral_idle.mp4    │◄──────────────────┐
                    │  (looping)           │                   │
                    └────────┬─────────────┘                   │
                             │ click                           │
                             ▼                                 │
                    ┌──────────────────────┐                   │
                    │   TRANSITION-OUT     │                   │
                    │ neutral_to_X.mp4     │                   │
                    │  (1.0× speed)        │                   │
                    └────────┬─────────────┘                   │
                             │ video ends                      │
                             ▼                                 │
                    ┌──────────────────────┐                   │
                    │   EMOTION-HOLD       │                   │
                    │     X.png            │                   │
                    └────────┬─────────────┘                   │
                             │ click                           │
                             ▼                                 │
                    ┌──────────────────────┐                   │
                    │   TRANSITION-BACK    │                   │
                    │ X_to_neutral.mp4     │                   │
                    │  (1.6× speed)        │───┐               │
                    └──────────────────────┘   │               │
                                               │ video ends    │
                                               ▼               │
                                        pendingTarget?         │
                                          ├── yes → TRANSITION-OUT
                                          └── no  ────────────►┘
```

### Flow Examples

**Click right × 3 from idle:**
```
idle (looping) → click right →
  play neutral_to_excited.mp4 (1.0×) → show excited.png → click right →
  play excited_to_neutral.mp4 (1.6×) → play neutral_to_happy.mp4 (1.0×) → show happy.png → click right →
  play happy_to_neutral.mp4 (1.6×) → play neutral_to_pleading.mp4 (1.0×) → show pleading.png
```

**Click left from happy:**
```
show happy.png → click left →
  play happy_to_neutral.mp4 (1.6×) → play neutral_to_excited.mp4 (1.0×) → show excited.png
```

### Emotion Cycle Order

Neutral is the idle hub, not a selectable emotion. Left/right cycles through:

```
excited → happy → pleading → sad → smug → surprised → thinking → (wraps)
```

### Video Assets

Videos are stored in `/avatars/<agent-id>/videos/`:

| File | Direction | Speed |
|---|---|---|
| `neutral_idle.mp4` | Idle loop | 1.0× (looped) |
| `neutral_to_excited.mp4` | Forward | 1.0× |
| `neutral_to_happy.mp4` | Forward | 1.0× |
| `neutral_to_pleading.mp4` | Forward | 1.0× |
| `neutral_to_sad.mp4` | Forward | 1.0× |
| `neutral_to_smug.mp4` | Forward | 1.0× |
| `neutral_to_surprised.mp4` | Forward | 1.0× |
| `neutral_to_thinking.mp4` | Forward | 1.0× |
| `excited_to_neutral.mp4` | Reverse | 1.6× (when chaining) |
| `happy_to_neutral.mp4` | Reverse | 1.6× |
| `pleading_to_neutral.mp4` | Reverse | 1.6× |
| `sad_to_neutral.mp4` | Reverse | 1.6× |
| `smug_to_neutral.mp4` | Reverse | 1.6× |
| `surprised_to_neutral.mp4` | Reverse | 1.6× |
| `thinking_to_neutral.mp4` | Reverse | 1.6× |

Videos are generated with **Veo 3.1** using first+last frame interpolation (start emotion PNG → end emotion PNG), 8 seconds, 9:16 portrait, cropped to circle via CSS `object-fit: cover`.

### Fallback Behavior

- **No video folder**: shows static PNGs only (no video, no click zones)
- **Missing transition video**: snaps directly to the target PNG
- **Video load error**: falls back to static PNG and resets state

---

## Carousel Expression Map

As avatars slide through the carousel, expressions change based on proximity to center:

```
  Far away (d ≥ 3)       → 😐 neutral     (resting, idle)
  Outer ring (d < 3)     → 😢 sad         (wishing they were chosen)
  Next ring (d < 2)      → 😲 surprised   (noticing the spotlight)
  Neighbors (d < 1.2)    → 🤩 excited     (almost there!)
  Center (d < 0.3)       → 🥺 pleading    (pick me! big eyes)
  Clicked / Saved        → 🤩 excited     (yay, selected!)
  Saved (2s flash)       → 😊 happy       (confirmed save glow)
```

## Expression Assets

Each avatar has these PNG files in `/avatars/<id>/`:

| File            | Used when                         |
|-----------------|-----------------------------------|
| `neutral.png`   | Far from center (d ≥ 3)            |
| `sad.png`       | Outer ring (2 ≤ d < 3)             |
| `surprised.png` | Next ring (1.2 ≤ d < 2)            |
| `excited.png`   | Neighbors (0.3 ≤ d < 1.2) or clicked |
| `pleading.png`  | At center (d < 0.3)              |
| `happy.png`     | Save confirmation (2s flash)      |
| `smug.png`      | Available (not used in carousel)  |
| `thinking.png`  | Available (not used in carousel)  |

## Named Identities

Each avatar has a Bible name, localized across 8 languages:

| Avatar ID | English | Deutsch | Español | Français | Português | Italiano | 日本語 | 中文 |
|-----------|---------|---------|---------|----------|-----------|----------|--------|------|
| chibi-01  | Ezra    | Esra    | Esdras  | Esdras   | Esdras    | Esdra    | エズラ   | 以斯拉 |
| chibi-02  | Miriam  | Mirjam  | Miriam  | Myriam   | Miriã     | Miriam   | ミリアム  | 米利暗 |
| chibi-03  | Caleb   | Kaleb   | Caleb   | Caleb    | Caleb     | Caleb    | カレブ   | 迦勒  |
| chibi-04  | Esther  | Esther  | Ester   | Esther   | Ester     | Ester    | エステル  | 以斯帖 |
| chibi-05  | Josiah  | Josia   | Josías  | Josias   | Josias    | Giosia   | ヨシヤ   | 约西亚 |
| chibi-06  | Naomi   | Noomi   | Noemí   | Noémi    | Noemi     | Noemi    | ナオミ   | 拿俄米 |

Users can also set a **custom name** that overrides the default via Settings → Agent Name input.
The custom name persists in the `agent_name` column of `user_sessions`.

## Chat Display

In the chat, assistant messages show `"Agent {Name}"` (e.g. "Agent Ezra") instead of the old "🤖 Agent".
The name adapts to the selected language and any custom override.

---

## Adding Emotions to a New Agent

This section explains how to add avatar expressions to any new agent.

### 1. Create the Avatar Folder

Create a directory at:
```
packages/web/public/avatars/agent-<intent>/
```

Where `<intent>` matches the agent's intent value (e.g. `opencode_plan`, `implement`, `review`).

### 2. Generate Emotion PNGs

You need **8 PNG files**, one per emotion:

| File | Emotion | Description |
|---|---|---|
| `neutral.png` | 😐 Neutral | Default idle expression |
| `excited.png` | 🤩 Excited | Energetic, celebrating |
| `happy.png` | 😊 Happy | Warm, content |
| `pleading.png` | 🥺 Pleading | Big eyes, begging |
| `sad.png` | 😢 Sad | Frowning, disappointed |
| `smug.png` | 😏 Smug | Confident, proud |
| `surprised.png` | 😲 Surprised | Shocked, eyes wide |
| `thinking.png` | 🤔 Thinking | Contemplative, planning |

### Image Specifications

| Property | Value |
|---|---|
| **Format** | PNG with alpha channel (RGBA) |
| **Size** | 640 × 640 pixels |
| **Background** | White or transparent |
| **File size** | ~400–800 KB each |
| **Style** | Consistent across all 8 emotions |
| **Composition** | Single character, centered, full body |

### 3. (Optional) Generate Transition Videos

For animated transitions, create a `videos/` subdirectory:

```
agent-<intent>/
├── *.png (8 emotion files)
└── videos/
    ├── neutral_idle.mp4          ← loops while idle
    ├── neutral_to_excited.mp4    ← forward transitions (7 files)
    ├── neutral_to_happy.mp4
    ├── neutral_to_pleading.mp4
    ├── neutral_to_sad.mp4
    ├── neutral_to_smug.mp4
    ├── neutral_to_surprised.mp4
    ├── neutral_to_thinking.mp4
    ├── excited_to_neutral.mp4    ← reverse transitions (7 files)
    ├── happy_to_neutral.mp4
    ├── pleading_to_neutral.mp4
    ├── sad_to_neutral.mp4
    ├── smug_to_neutral.mp4
    ├── surprised_to_neutral.mp4
    └── thinking_to_neutral.mp4
```

**Video specs:** MP4 (H.264), 9:16 portrait, ~8 seconds, ~1.5–3 MB each.
Videos can be generated with **Veo 3.1** using first+last frame interpolation.

> **Tip:** Videos are entirely optional. The system gracefully falls back to static PNGs when no videos exist.

### 4. Wire the Avatar ID

The backend's `seedBuiltInAgents` method in `AgentDefinitionService.ts` automatically sets `avatar: 'agent-<intent>'`, so built-in agents are auto-mapped. For custom agents, set the `avatar` field to match the folder name.

### 5. Test

1. Start the dev server: `npm run dev`
2. Open **Agent Builder** → select your new agent
3. The avatar should display `neutral.png` by default
4. If videos exist, the avatar should play `neutral_idle.mp4` loop
5. Click left/right arrows to cycle through emotions
6. Verify all 8 expressions render correctly

### Using the Generation Script

A Nano Banana V2 (Gemini API) script is available at `/tmp/generate_avatar_emotions.py`:

```bash
export GEMINI_API_KEY="your-key"
python3 /tmp/generate_avatar_emotions.py
```

The script uses existing agent avatars (`agent-implement`) as **style references** to ensure visual consistency. To add new agents, edit the `AGENTS` dict in the script.

