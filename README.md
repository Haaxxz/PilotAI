# PilotAI for iOS

PilotAI is a native iOS client for the **PilotAI** mobile autonomous agent and AI assistant platform. Built from scratch with Swift & SwiftUI, it mirrors the design, chat interactions, model provider matrix, roleplay companions, persistent memories, and data backup schemas of the Android PilotAI APK.

---

## Features

- **Direct Chat & Autonomous Agent**:
  - Multi-turn conversation management with real-time SSE streaming.
  - Expandable **Thinking Process** blocks (DeepSeek-R1, OpenAI o1/o3-mini reasoning tokens).
  - Visual **Tool Invocation** status cards and tool output inspector.
  - Markdown formatting and one-tap code copying.
- **Model Providers**:
  - Out-of-the-box templates for **OpenAI**, **Anthropic**, **DeepSeek**, **Kimi (Moonshot)**, **Alibaba Bailian**, **MiniMax**, **SiliconFlow**, and **OpenRouter**.
  - Local endpoint support (**Ollama**, **LM Studio**) via LAN.
  - Custom HTTP request headers with per-header key/value pairs.
- **Roleplay Characters**:
  - Built-in personas including **Xiaoman**, **Traveler**, and **Kernel Pilot**.
  - Character detail inspector and dedicated conversation launcher.
- **Core Memory**:
  - Persistent user memory markdown editor.
  - Automatic prompt injection across all conversations with estimated token accounting.
- **Interactive Terminal**:
  - Sandboxed command shell simulation with command history and monospace console formatting.
- **Cross-Platform Backup Compatibility**:
  - Imports and exports `.json` backups fully compatible with PilotAI / Eta Android backups (`format: "eta-backup"`, `schemaVersion: 2`).

---

## Architecture & Project Structure

```text
PilotAI-iOS/
├── .github/workflows/
│   └── ios-build.yml       # Automated GitHub Actions workflow for macOS CI & IPA export
├── PilotAI/
│   ├── App/
│   │   ├── PilotAIApp.swift    # @main application lifecycle
│   │   └── AppState.swift      # Global environment observable store
│   ├── Models/
│   │   ├── Message.swift       # Message, Role, ToolCall definitions
│   │   ├── Conversation.swift  # Conversation thread state
│   │   ├── Provider.swift      # Provider and Model configurations
│   │   ├── Character.swift     # Roleplay character specs
│   │   ├── Memory.swift        # Core memory schema
│   │   └── Settings.swift      # Application preferences
│   ├── Services/
│   │   ├── OpenAIService.swift      # AsyncThrowingStream SSE parser
│   │   ├── AgentEngine.swift        # Agent loop and memory injection orchestrator
│   │   ├── StorageService.swift     # Local document persistence
│   │   └── BackupService.swift      # JSON backup import/export
│   ├── Views/
│   │   ├── MainTabView.swift        # Tab bar navigation
│   │   ├── Chat/                    # ChatView, MessageBubble, ThinkingView, InputBar
│   │   ├── Characters/              # Character list and detail views
│   │   ├── Memory/                  # Markdown memory editor
│   │   ├── Terminal/                # Console interface
│   │   ├── Providers/               # Model provider credentials and endpoints
│   │   └── Settings/                # Appearance, backup, and app info
│   └── Resources/
│       ├── Info.plist               # Permissions, identifiers, and device configs
│       ├── LaunchScreen.storyboard  # System launch interface
│       └── Assets.xcassets/         # App icons and color palettes
├── PilotAI.xcodeproj/
│   └── project.pbxproj              # Native Xcode project
├── scripts/
│   └── package_ipa.sh               # Local IPA packaging script (Linux & macOS)
└── build/
    └── PilotAI.ipa                  # Generated iOS Application Archive
```

---

## Building

### Option A: Local Packaging on Linux (No macOS Required)
Run the automated packaging script to compile the Mach-O `arm64` binary and bundle the application archive:
```bash
./scripts/package_ipa.sh
```
Output archive will be generated at: `build/PilotAI.ipa`.

### Option B: Native macOS & Xcode
1. Open `PilotAI.xcodeproj` in Xcode 15.0 or later on macOS.
2. Select your development team under **Signing & Capabilities**.
3. Select an iOS device or simulator, and press **Cmd + R** to run.
4. To export an archive: **Product &rarr; Archive &rarr; Distribute App &rarr; Ad Hoc or Sideloading**.

### Option C: GitHub Actions Cloud CI
Push to the repository with the provided `.github/workflows/ios-build.yml`. GitHub Actions runs on `macos-14`, builds the project with `xcodebuild`, packages `PilotAI-unsigned.ipa`, and uploads it as a workflow artifact.

---

## Installation / Sideloading
The generated `PilotAI.ipa` is ready for sideloading on non-jailbroken and jailbroken iOS devices:
- **TrollStore** (iOS 14.0 &ndash; 17.0)
- **AltStore / SideStore**
- **Scarlet / Sideloadly**
