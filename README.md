# Hermion 🎙️

**Privacy-first, system-wide voice keyboard powered by Moonshine ASR.**

> Type with your voice — anywhere on your computer. All speech processing happens 100% on-device. No audio is ever sent to the cloud.

---

## Table of Contents

- [What is the Sidecar?](#what-is-the-sidecar)
- [Architecture & Data Flow](#architecture--data-flow)
- [Prerequisites](#prerequisites)
- [How to Run in Development](#how-to-run-in-development)
- [How to Build for Production](#how-to-build-for-production)
- [Project Structure](#project-structure)
- [Key Features](#key-features)
- [License](#license)

---

## What is the Sidecar?

In Tauri applications, a **sidecar** is an independent companion binary that runs alongside the main desktop app as a separate process.

### Why does Hermion use a sidecar?

1. **Inference Isolation**: Automatic Speech Recognition (ASR) with Moonshine and Voice Activity Detection (VAD) are compute-heavy machine learning workloads. Running them in a dedicated sidecar process ensures the main UI and OS event loops never stutter or freeze.
2. **Fault Tolerance**: If an AI model runs out of memory or encounters an issue, only the sidecar restarts — the main Hermion desktop app, system tray, and floating overlay remain fully responsive.
3. **Clean IPC Protocol**: The main Tauri app and the sidecar communicate via fast, lightweight JSON messages over standard input/output (`stdin` / `stdout`).

```
[ Microphone ] ──► [ Tauri Core (Rust) ] ──(Audio Chunks / Stdin)──► [ Sidecar (Moonshine ASR) ]
                         │                                                    │
                 (System Paste / Key)                                 (JSON Events / Stdout)
                         │                                                    │
                         ▼                                                    ▼
                 [ Focused App ] ◄─────── [ Floating Overlay UI ] ◄───────────┘
```

---

## Architecture & Data Flow

1. **User triggers input**: Press `F5` (push-to-talk or toggle mode) or click the microphone button.
2. **Audio Capture**: Tauri's Rust backend captures microphone audio via `cpal`, converts it to 16kHz mono PCM, and calculates real-time RMS levels for the visual waveform.
3. **Streaming to Sidecar**: Base64-encoded audio chunks are piped into the `hermion-sidecar` process.
4. **On-Device Inference**: Moonshine ASR runs streaming inference and emits partial and final transcriptions.
5. **Real-time UI**: The floating overlay pill displays the live transcript and mini-waveform.
6. **System-wide Injection**: When speech ends, the transcribed text is automatically typed or pasted into whichever app is currently focused (VS Code, Chrome, Terminal, Slack, etc.).

---

## Prerequisites

Ensure you have the following installed on your machine:

- **Node.js**: `v20+` ([Download](https://nodejs.org/))
- **Rust & Cargo**: `1.80+` ([Install via rustup](https://rustup.rs/))
- **Platform requirements**:
  - **macOS**: macOS 12+ (Xcode Command Line Tools installed via `xcode-select --install`)
  - **Windows**: Windows 10/11 with WebView2 runtime
  - **Linux**: `libwebkit2gtk-4.1-dev`, `build-essential`, `curl`, `wget`, `file`, `libssl-dev`, `libasound2-dev`

---

## How to Run in Development

### 1. Clone the repository
```bash
git clone https://github.com/rimraf-adi/hermion.git
cd hermion
```

### 2. Install frontend dependencies
```bash
npm install
```

### 3. Build the sidecar binary
Before launching the app, compile the companion inference sidecar:
```bash
npm run build:sidecar
```

### 4. Start the development server
```bash
npm run tauri dev
```

This will:
- Start the Vite development server for the SolidJS frontend (`http://localhost:1420`).
- Compile the Tauri Rust core.
- Launch the Hermion desktop application with hot-reloading enabled.

---

## How to Build for Production

To create a standalone production release package (`.dmg` on macOS, `.msi` / `.exe` on Windows, `.deb` / `.AppImage` on Linux):

```bash
# 1. Build the sidecar binary
npm run build:sidecar

# 2. Build the production bundle
npm run tauri build
```

The output installers will be generated in:
```
src-tauri/target/release/bundle/
```

---

## Project Structure

```
hermion/
├── src/                          # Frontend (SolidJS + TypeScript)
│   ├── App.tsx                   # Main app component & routing
│   ├── components/
│   │   ├── HomeView.tsx          # Voice dictation dashboard & waveform
│   │   ├── OverlayView.tsx       # Minimal floating always-on-top pill
│   │   ├── SettingsView.tsx      # Audio, model, hotkey & theme settings
│   │   ├── HistoryView.tsx       # Searchable transcription history
│   │   ├── Waveform.tsx          # Real-time audio visualizer
│   │   └── Onboarding.tsx        # First-run setup wizard
│   ├── stores/                   # Reactive state stores
│   │   └── app-store.ts
│   ├── lib/                      # Tauri typed IPC bridge
│   │   └── tauri-bridge.ts
│   └── styles/
│       └── index.css             # Design system & dark theme tokens
│
├── src-tauri/                    # Tauri Backend (Rust)
│   ├── src/
│   │   ├── lib.rs                # App entry point, system tray, hotkeys
│   │   ├── main.rs               # Binary entry point
│   │   ├── commands.rs           # Frontend IPC command handlers
│   │   ├── sidecar.rs            # Sidecar lifecycle & stdio piping manager
│   │   ├── audio.rs              # Microphone capture & 16kHz resampling (cpal)
│   │   ├── injection.rs          # System-wide text injection (enigo & clipboard)
│   │   ├── db.rs                 # SQLite persistence (rusqlite)
│   │   └── models.rs             # Shared data models & IPC protocol types
│   ├── bin/                      # Compiled sidecar binary directory
│   ├── capabilities/             # Tauri v2 security & permission capabilities
│   └── tauri.conf.json           # Tauri configuration
│
├── src-sidecar/                  # Moonshine ASR Sidecar (Rust)
│   └── src/
│       ├── main.rs               # JSON stdio message loop (stdin/stdout)
│       ├── inference.rs          # Moonshine ONNX model pipeline & VAD
│       └── protocol.rs           # Sidecar protocol types
│
├── package.json                  # NPM scripts & dependencies
└── vite.config.ts                # Vite build configuration
```

---

## Key Features

- 🎙️ **Push-to-Talk / Toggle** — Global `F5` hotkey works anywhere in your operating system.
- ⚡ **Real-Time Streaming** — See words transcribed as you speak with sub-200ms latency.
- 🔒 **100% Offline & Private** — Audio never leaves your device.
- ⌨️ **System-Wide Input** — Types into any active application (code editors, browsers, terminals, chat apps).
- 🪟 **Floating Pill Overlay** — Minimal, transparent, always-on-top overlay for distraction-free dictation.
- 📝 **Spoken Dictation Commands** — Automatically replaces spoken commands like *"new line"*, *"period"*, *"comma"*, *"open paren"*, etc.
- 🔍 **Searchable History** — Re-inject, copy, or search through past transcriptions saved locally in SQLite.
- 🧠 **Optional Local LLM Cleanup** — Connect to local Ollama (`llama3`, `mistral`, etc.) for grammar and punctuation polishing.

---

## License

MIT © [Hermion Contributors](https://github.com/rimraf-adi/hermion)
