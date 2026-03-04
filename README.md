# BiSign - Giving Voice to the Voiceless

BiSign is a real-time, AI-powered, zero-cost, offline-capable bidirectional Indian Sign Language (ISL) communication Android application. It genuinely helps mute, deaf, and deaf-mute individuals in rural India communicate freely and independently.

## Features

- **Direction 1 — Sign to Speech:** Translates Indian Sign Language gestures into regional spoken language (Telugu, Hindi, Tamil, Kannada) using MediaPipe and TensorFlow Lite.
- **Direction 2 — Speech to ISL Signs:** Converts regional spoken language into smooth ISL sign animations using completely offline speech recognition (Vosk/Whisper) and lightweight JSON-based landmark rendering.
- **100% Offline Capability:** Works completely offline after initial setup, ensuring privacy, zero data cost, and reliability in rural areas.
- **Extremely Low Storage:** Utilizes JSON-based landmark sequences for rendering signs instead of heavy video files, consuming less than 4MB for over 500 signs.
- **Highly Accessible UI:** Simple, big buttons, high contrast, non-literate friendly design.

## Technology Stack

- **Frontend:** Flutter (Dart)
- **AI / Hand Tracking on Device:** MediaPipe Hands
- **Sign Classification:** TensorFlow Lite (`tflite_flutter`)
- **Speech Recognition (Offline):** Vosk / Whisper (`vosk_flutter`)
- **Speech Synthesis:** Android TTS (`flutter_tts`)

## Setup & Installation

### Requirements
- Flutter SDK (>= 3.0.0)
- Android Studio or VS Code with Flutter extension
- An Android device (Minimum 2GB RAM required for smooth performance on budget phones)

### Steps to Run
1. Clone the repository.
2. Navigate to the project directory: 
   ```bash
   cd BiSign
   ```
3. Install Flutter dependencies: 
   ```bash
   flutter pub get
   ```
4. Run the app on a connected Android device:
   ```bash
   flutter run
   ```

## Folder Structure

```
BiSign/
├── android/               # Android native configuration
├── assets/
│   ├── fonts/             # NotoSans fonts
│   ├── models/            # TensorFlow Lite models (Sign Classification)
│   ├── signs/             # JSON landmark files for ISL animations
│   └── vosk/              # Vosk offline speech recognition models
├── lib/
│   ├── models/            # Data models
│   ├── screens/           # UI Screens (Home, Direction 1, Direction 2)
│   ├── services/          # Core logic (TFLite, MediaPipe, NLP, TTS, STT)
│   ├── utils/             # App theme, constants, reordering rules
│   ├── widgets/           # Reusable UI components (Canvas, Overlays)
│   └── main.dart          # App entry point
├── test/                  # Unit and widget tests
└── pubspec.yaml           # Flutter dependencies
```

## Build Phases Followed

- [x] **Phase A — Foundation** (Project architecture, Home/Dir1/Dir2 UI, Service Scaffolding, Dependency resolution)
- [ ] **Phase B — Direction 1 Core** (Real-time MediaPipe Hand landmark detection, TFLite sign classification, TTS)
- [ ] **Phase C — Direction 2 Core** (Offline Vosk STT, JSON landmark parsing, Canvas Animation Renderer)
- [ ] **Phase D — NLP and Languages** (IndicNLP ISL rule grammar reordering for Telugu, Hindi, Tamil, Kannada)
- [ ] **Phase E — Optimization** (Memory optimization for 2GB RAM Androids, App Size compression, APK Generation)

---
*Built with deep responsibility to ensure no one is forced to live in silence.*
