#!/usr/bin/env bash
set -e

VERSION="1.0.0"
DMG_NAME="Hermion-v${VERSION}-macOS-arm64.dmg"
APP_DIR="Hermion.app"
STAGING_DIR=".dmg_staging"

echo "📦 Creating professional DMG installer: $DMG_NAME..."

# 1. Build and sign app
./scripts/build_app.sh

# 2. Setup DMG Staging Folder
rm -rf "$STAGING_DIR" "$DMG_NAME"
mkdir -p "$STAGING_DIR"

# Copy App
cp -R "$APP_DIR" "$STAGING_DIR/"

# Symlink Applications folder
ln -s /Applications "$STAGING_DIR/Applications"

# 3. Create DMG
hdiutil create -volname "Hermion" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# Clean staging
rm -rf "$STAGING_DIR"

echo "✅ Professional DMG installer created successfully: $DMG_NAME"
ls -lh "$DMG_NAME"
