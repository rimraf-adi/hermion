# Hermion 🎙️

**Hermion** is an open-source, privacy-first, system-wide native macOS voice keyboard with a floating **Wispr Flow** style pill overlay.

Anywhere you can type on your Mac — Terminal, VS Code, Cursor, Chrome, Slack, Notes, etc. — simply press **`F5`** (or click the Menu Bar icon), speak your thoughts, and Hermion instantly transcribes and injects the text into your active app.

---

## ✨ Features

- 🛸 **Wispr Flow Floating Overlay**: An ultra-compact, non-intrusive floating pill (`✕  ■■■■■■■■  ■`) that floats throughout your entire macOS workspace across all Desktops and fullscreen apps without stealing focus from your cursor.
- ⚡ **Real-Time 60fps Equalizer**: Dynamic animated sound waves that bounce with speech amplitude.
- 🔒 **100% On-Device & Private**: Runs directly on Apple Silicon with zero network requests and zero latency.
- ⌨️ **Universal Text Injection**: Injects transcribed text into any focused macOS input field with automatic clipboard preservation and restoration.
- 🗣️ **Spoken Commands**: Automatic punctuation and voice commands ("new line", "comma", "period", "question mark", "open paren", "quote", etc.).
- 🌐 **Menu Bar Integration**: Native macOS status bar icon for instant access, history review, settings, and controls.

---

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+ (Apple Silicon or Intel)
- Xcode Command Line Tools (`xcode-select --install`)

### Build & Run
```bash
# Clone the repository
git clone https://github.com/rimraf-adi/hermion.git
cd hermion

# Build and launch Hermion
swift run Hermion
```

Or build a release binary:
```bash
swift build -c release
# Executable located at: .build/release/Hermion
```

---

## 🎯 How to Use

1. **Start Hermion**: Run `swift run Hermion`.
2. **Open any app**: (VS Code, TextEdit, Chrome, Terminal, Slack, etc.).
3. **Press `F5`** (or click the waveform icon in your macOS Menu Bar):
   - The Wispr Flow pill appears floating smoothly on screen.
   - Speak your words or code.
4. **Finish & Paste**:
   - Press **`F5`** again or click the **Red Stop button (`■`)** to insert your text.
5. **Cancel**:
   - Click the **Grey Cancel button (`✕`)** to discard the audio without typing anything.

---

## 🛠️ Architecture

Hermion is built with **100% Native Swift, SwiftUI, and AppKit**:

- **Audio Pipeline**: `AVAudioEngine` real-time microphone tap + 60fps RMS power visualizer.
- **Speech Engine**: Apple Neural Engine on-device `SFSpeechRecognizer` with continuous token streaming.
- **System Overlay**: `NSPanel` with `.nonactivatingPanel` and `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, ensuring it never steals keyboard focus.
- **Injection Engine**: `CGEvent` + `NSPasteboard` with automatic clipboard snapshot and restoration.

---

## 📄 License
MIT License
