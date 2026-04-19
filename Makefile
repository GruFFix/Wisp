.PHONY: generate build run dmg clean

APP_NAME   = Wisp
APP_BUNDLE = Wisp.app
VERSION    = 1.0
DMG_NAME   = $(APP_NAME)-$(VERSION).dmg

generate:
	xcodegen generate

build: generate
	xcodebuild -project Wisp.xcodeproj -scheme Wisp -configuration Debug build SYMROOT=$(PWD)/build

run: build
	open ./build/Debug/Wisp.app

# ── Release build + DMG ────────────────────────────────────────────────────────
dmg:
	@echo "▶︎  Building Release..."
	xcodebuild -project Wisp.xcodeproj \
	           -scheme Wisp \
	           -configuration Release \
	           SYMROOT=$(PWD)/build \
	           build
	@echo "▶︎  Staging app..."
	@rm -rf /tmp/wisp-dmg-stage && mkdir /tmp/wisp-dmg-stage
	@cp -R "./build/Release/$(APP_BUNDLE)" /tmp/wisp-dmg-stage/
	@echo "▶︎  Creating DMG..."
	@rm -f "$(DMG_NAME)"
	create-dmg \
	  --volname "$(APP_NAME)" \
	  --volicon "Wisp/Assets.xcassets/AppIcon.appiconset/icon_512.png" \
	  --window-size 540 380 \
	  --icon-size 128 \
	  --icon "$(APP_BUNDLE)" 160 185 \
	  --app-drop-link 380 185 \
	  --hide-extension "$(APP_BUNDLE)" \
	  --no-internet-enable \
	  "$(DMG_NAME)" \
	  "/tmp/wisp-dmg-stage/"
	@rm -rf /tmp/wisp-dmg-stage
	@echo "✅  $(DMG_NAME) ready"

clean:
	rm -rf build/ Wisp.xcodeproj $(DMG_NAME)
