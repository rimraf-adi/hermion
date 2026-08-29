<div align="center">

# Hermion 🎙️
**The Open-Source, Private, Ultra-Fast Voice Keyboard for macOS**

*Whisper, dictate, and speak your thoughts directly into any application with zero cloud latency.*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20%7C%20Sonoma%20%7C%20Sequoia-black?style=for-the-badge&logo=apple)](https://apple.com)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%2F%20M2%20%2F%20M3%20%2F%20M4-blue?style=for-the-badge&logo=apple)](https://apple.com)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-success?style=for-the-badge&logo=shield)](https://github.com/rimraf-adi/hermion)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)

[Features](#-key-features) • [Installation](#-installation) • [How to Use](#-how-to-use) • [Keyboard Shortcuts](#-keyboard-shortcuts) • [Architecture](#-architecture) • [Building from Source](#-building-from-source)

</div>

---

## ⚡ Overview

**Hermion** is a native, privacy-first voice keyboard for macOS featuring a **Wispr Flow / Dynamic Island** style morphing glass pill. 

Wherever you can type on your Mac — **VS Code, Cursor, Chrome, Terminal, Slack, Obsidian, Xcode, Notes, Telegram, etc.** — simply press **`Right Shift`** (or your custom shortcut), speak naturally, and Hermion will stream and inject your text into the active field with instantaneous speed.

Zero cloud API calls. Zero subscription fees. 100% local execution on Apple Silicon.

---

## ✨ Key Features

### 🛸 Fluid Morphing Glass Island
- **Ultra-Minimal Idle State**: A sleek, unobtrusive frosted glass micro-capsule (`84px`) that floats above all apps and full-screen spaces without stealing focus.
- **Dynamic Recording Island**: Smoothly widens (`360px`) to display sound-reactive equalizer waves, real-time live subtitle streaming, and glowing theme accents.
- **120Hz Jitter-Free Dragging**: Grab and position the pill anywhere across single or multi-monitor workspaces with sub-pixel hardware precision.
- **Full Customization**: Customize resting width, recording expansion width, and optional custom idle labels in Settings.

### 🧠 Dual-Engine ASR Architecture
- **Apple Neural Engine (ANE)**: Native macOS on-device speech model with continuous token streaming.
- **Moonshine ASR**: Advanced Transformer-based speech recognition with **Apple MLX Metal GPU acceleration** and automatic **CPU low-power fallback**.
- **Natural Auto-Punctuation & Voice Commands**: Spoken commands for punctuation (*"comma"*, *"new line"*, *"question mark"*, *"open quote"*, etc.).

### 🎙️ DSP Noise Reduction & Live Dry-Run
- **Real-Time Spectral Noise Gate**: Filters out background room acoustics, AC/fan hum, and keyboard mechanical switches.
- **80Hz High-Pass Rumble Filter**: DC-blocking Butterworth filter that cuts microphone pops and desk vibrations.
- **5 Tuned Profiles**: *Off (Raw Audio)*, *Light (Subtle Gate)*, *Medium (Balanced)*, *Aggressive (Noisy Room)*, and *Voice Isolation*.
- **Interactive Dry-Run Meter**: Live dual VU meters comparing raw microphone input vs clean voice output in real-time.

### 🎧 Dynamic Microphone Device Switcher
- Automatically discovers and switches between all input sources:
  - Built-in MacBook Pro / Air microphones
  - AirPods, AirPods Pro, and AirPods Max
  - External USB, XLR, or Bluetooth studio microphones (Blue Yeti, Shure, Rode, etc.)

### 🎨 Curated Color Themes & Gradients
- **🌌 Nebula Purple**: Royal Violet (`#8B5CF6`) → Deep Indigo (`#6366F1`) *(Wispr Classic)*
- **⚡ Cyber Cyan**: Electric Azure (`#06B6D4`) → Neon Teal (`#14B8A6`)
- **🌅 Sunset Coral**: Vibrant Amber (`#F59E0B`) → Rose Red (`#F43F5E`)
- **🍃 Emerald Mint**: Crisp Mint (`#10B981`) → Deep Forest (`#059669`)
- **🌑 Obsidian Slate**: Titanium Silver (`#E2E8F0`) → Charcoal Zinc (`#71717A`)

### 🚀 System Integration & Productivity
- **Universal Text Injection**: Dual-channel `CGEvent` + `System Events` paste engine that guarantees instant text insertion across Electron, Terminal, and sandboxed apps.
- **Launch on Startup**: Native macOS 13+ background login registration via `SMAppService`.
- **Global `⌘Q` & Standard Shortcuts**: Native application menu with standard Mac keybindings.

---

## 🎯 How to Use

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Focus any text field (VS Code, Chrome, Terminal, Slack)  │
│ 2. Tap [Right Shift ⇧] (or Double-Tap Shift)                │
│ 3. Speak your thoughts naturally                            │
│ 4. Press [Enter ↵] or tap [Right Shift ⇧] to Paste (⌘V)     │
└─────────────────────────────────────────────────────────────┘
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Right Shift (⇧)`** | **Toggle Dictation** | Default universal hotkey. Zero conflicts with macOS Siri/Dictation. |
| **`Enter (↵)`** | **Finish & Paste** | Immediately commits transcription and pastes into the active input. |
| **`Esc`** | **Cancel Dictation** | Immediately discards the recording without injecting text. |
| **`⌘Q`** | **Quit App** | Cleanly terminates all background processes. |
| **`⌘,`** | **Open Settings** | Opens the Hermion preferences panel. |

*Alternative hotkeys available in Settings: `Double Shift (⇧ ⇧)`, `Shift + Space (⇧ Space)`, `Option + Space (⌥ Space)`, `Control + Space (⌃ Space)`.*

---

## 📦 Installation

### Option 1: Download DMG Installer (Recommended)
Download the latest `Hermion-v1.0.0-macOS-arm64.dmg` from the [Releases](https://github.com/rimraf-adi/hermion/releases) tab and drag **Hermion.app** into your `/Applications` folder.

### Option 2: Build with Makefile
```bash
# Clone the repository
git clone https://github.com/rimraf-adi/hermion.git
cd hermion

# Build, sign, and launch Hermion
make run
```

---

## 🛠️ Makefile Commands

| Command | Description |
| :--- | :--- |
| **`make app`** | Compiles release binary, builds `.app` bundle, codesigns, and resets TCC permissions |
| **`make dmg`** | Packages `Hermion.app` into a distributable `Hermion-v1.0.0-macOS-arm64.dmg` |
| **`make run`** | Rebuilds and launches the app in a single command |
| **`make install`** | Installs `Hermion.app` directly into `/Applications` |
| **`make kill`** | Gracefully terminates all active Hermion background instances |
| **`make clean`** | Removes all `.build`, staging, and DMG artifacts |

---

## 🏗️ Architecture

```
Hermion/
├── Sources/Hermion/
│   ├── App/                  # App lifecycle & AppDelegate
│   ├── Core/                 # AppState orchestrator & event bus
│   ├── Audio/                # AVAudioEngine, DSP NoiseFilter, MicrophoneManager
│   ├── ASR/                  # SFSpeechRecognizer & Moonshine MLX/CPU Engine
│   ├── Hotkeys/              # Universal CGEventTap hardware key interceptor
│   ├── Injection/            # Robust text injection & accessibility handler
│   ├── Storage/              # HistoryStorage & LaunchOnStartupManager
│   └── UI/                   # SwiftUI & AppKit Glassmorphism Views
│       ├── WisprPillView.swift          # Dynamic Island morphing capsule
│       ├── FloatingOverlayPanel.swift   # Non-activating floating NSPanel
│       ├── MainDashboardView.swift      # Primary Voice & History dashboard
│       ├── SettingsView.swift           # Engine, hotkeys, theme & mic settings
│       ├── NoiseFilterDryRunView.swift  # Dual VU meters & live audio tester
│       └── AppTheme.swift               # Palette & gradient manager
├── scripts/
│   ├── build_app.sh          # Automated bundling & ad-hoc codesigning
│   └── create_dmg.sh         # DMG packaging automation
└── Makefile                  # Developer workflow targets
```

---

## 🔒 Privacy & Security Guarantee

Hermion is engineered with privacy as a foundational principle:
- **Zero Network Egress**: Speech recognition runs 100% locally on your Mac's Neural Engine and Apple Silicon GPU.
- **No Telemetry**: No user tracking, no third-party SDKs, no external server connections.
- **Local History Storage**: Transcription logs are stored strictly on your local disk in `~/Library/Application Support/Hermion/` and can be cleared at any time.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

<div align="center">
  <sub>Crafted with ❤️ for macOS power users.</sub>
</div>
