.PHONY: all build app dmg run test clean kill install

all: build

build:
	@echo "🔨 Compiling Swift binary..."
	swift build -c release

app:
	@echo "📦 Building Hermion.app bundle..."
	./scripts/build_app.sh

dmg:
	@echo "💿 Creating macOS DMG installer..."
	./scripts/create_dmg.sh

run: app
	@echo "🚀 Launching Hermion..."
	killall Hermion 2>/dev/null || true
	sleep 0.5
	open Hermion.app

install: app
	@echo "📥 Installing to /Applications..."
	cp -R Hermion.app /Applications/
	@echo "✅ Installed Hermion to /Applications"

kill:
	@echo "🛑 Terminating running Hermion instances..."
	killall Hermion 2>/dev/null || true

clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build Hermion.app *.dmg .dmg_staging
