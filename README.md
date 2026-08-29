# Hermion 🎙️

**Privacy-first, system-wide voice keyboard powered by Moonshine ASR.**

> Type with your voice — anywhere. All processing happens on-device. No cloud. No data collection. No API keys.

## Features

- 🎙️ **Push-to-Talk / Toggle** — Global hotkey (F5) activates voice input
- ⚡ **Real-time Streaming** — See words as you speak with sub-200ms latency
- 🔒 **100% Offline** — Moonshine ASR runs entirely on your device
- ⌨️ **System-wide** — Types into any app: browsers, IDEs, terminals, etc.
- 🧠 **Optional LLM Cleanup** — Grammar fixes via local Ollama
- 📝 **Dictation Commands** — Say "new line", "period", "comma", etc.
- 🌍 **Multi-language** — English, Chinese, Japanese, Korean, Arabic, and more
- 🔍 **History & Search** — Searchable log of all transcriptions

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Tauri v2 (Rust + native webview) |
| Frontend | SolidJS + TypeScript |
| ASR | Moonshine v2 (ONNX) |
| Audio | cpal (Rust) |
| Text Injection | enigo + arboard |
| Database | SQLite (rusqlite) |

## Getting Started

### Prerequisites

- [Rust](https://rustup.rs/) (1.80+)
- [Node.js](https://nodejs.org/) (20+)
- macOS 12+ / Windows 10+ / Linux (X11 or Wayland)

### Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run tauri dev

# Build for production
npm run tauri build
```

### Sidecar (Moonshine inference binary)

```bash
cd src-sidecar
cargo build --release
```

## Architecture

```
hermion/
├── src/                  # SolidJS frontend
├── src-tauri/            # Tauri Rust backend
│   └── src/
│       ├── lib.rs        # App setup, tray, hotkeys
│       ├── commands.rs   # IPC command handlers
│       ├── audio.rs      # Mic capture (cpal)
│       ├── injection.rs  # Text injection (enigo)
│       ├── db.rs         # SQLite persistence
│       └── models.rs     # Shared data types
└── src-sidecar/          # Moonshine ONNX sidecar
    └── src/
        ├── main.rs       # JSON-over-stdio message loop
        ├── inference.rs  # ONNX model loading & inference
        └── protocol.rs   # IPC message types
```

## License

MIT
