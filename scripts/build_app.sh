#!/usr/bin/env bash
set -e

echo "🔨 Building Hermion release binary..."
swift build -c release

APP_DIR="Hermion.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating $APP_DIR bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp .build/release/Hermion "$MACOS_DIR/Hermion"
chmod +x "$MACOS_DIR/Hermion"

cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Hermion</string>
    <key>CFBundleIdentifier</key>
    <string>com.hermion.voicekeyboard</string>
    <key>CFBundleName</key>
    <string>Hermion</string>
    <key>CFBundleDisplayName</key>
    <string>Hermion</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Hermion needs microphone access to transcribe your voice.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Hermion uses on-device Apple Silicon speech recognition for private local dictation.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Hermion needs Accessibility access to inject text into focused applications.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 Signing Hermion.app bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Hermion.app successfully built & signed!"
echo "🚀 Run with: open Hermion.app"
