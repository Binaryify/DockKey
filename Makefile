APP_NAME := DockKey
BUNDLE_ID := dev.binaryify.dockkey
EXECUTABLE_NAME := DockKey
VERSION := 0.3.0
BUILD_NUMBER := 3
CONFIG := release
BUILD_DIR := build
DIST_DIR := dist
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := .build/$(CONFIG)/$(EXECUTABLE_NAME)
ASSETS_DIR := Assets
ARTIFACT_VERSION ?= $(VERSION)
ARTIFACT_BASENAME := $(APP_NAME)-$(ARTIFACT_VERSION)-arm64
DMG_ROOT := $(BUILD_DIR)/dmg
DMG_DIR := $(DMG_ROOT)/$(APP_NAME)

.PHONY: run build app zip dmg release-artifacts clean

run:
	swift run $(EXECUTABLE_NAME)

build:
	swift build -c $(CONFIG)

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(EXECUTABLE)" "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"
	cp "$(ASSETS_DIR)/AppIcon.icns" "$(APP_DIR)/Contents/Resources/AppIcon.icns"
	cp "$(ASSETS_DIR)/MenuBarIconTemplate.png" "$(APP_DIR)/Contents/Resources/MenuBarIconTemplate.png"
	printf '%s\n' \
	'<?xml version="1.0" encoding="UTF-8"?>' \
	'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	'<plist version="1.0">' \
	'<dict>' \
	'  <key>CFBundleDevelopmentRegion</key>' \
	'  <string>zh_CN</string>' \
	'  <key>CFBundleExecutable</key>' \
	'  <string>$(APP_NAME)</string>' \
	'  <key>CFBundleIdentifier</key>' \
	'  <string>$(BUNDLE_ID)</string>' \
	'  <key>CFBundleIconFile</key>' \
	'  <string>AppIcon</string>' \
	'  <key>CFBundleInfoDictionaryVersion</key>' \
	'  <string>6.0</string>' \
	'  <key>CFBundleName</key>' \
	'  <string>$(APP_NAME)</string>' \
	'  <key>CFBundlePackageType</key>' \
	'  <string>APPL</string>' \
	'  <key>CFBundleShortVersionString</key>' \
	'  <string>$(VERSION)</string>' \
	'  <key>CFBundleVersion</key>' \
	'  <string>$(BUILD_NUMBER)</string>' \
	'  <key>LSMinimumSystemVersion</key>' \
	'  <string>13.0</string>' \
	'  <key>LSUIElement</key>' \
	'  <true/>' \
	'  <key>NSPrincipalClass</key>' \
	'  <string>NSApplication</string>' \
	'</dict>' \
	'</plist>' > "$(APP_DIR)/Contents/Info.plist"
	@echo "Created $(APP_DIR)"

zip: app
	mkdir -p "$(DIST_DIR)"
	rm -f "$(DIST_DIR)/$(ARTIFACT_BASENAME).zip" "$(DIST_DIR)/$(ARTIFACT_BASENAME).zip.sha256"
	ditto -c -k --keepParent "$(APP_DIR)" "$(DIST_DIR)/$(ARTIFACT_BASENAME).zip"
	shasum -a 256 "$(DIST_DIR)/$(ARTIFACT_BASENAME).zip" > "$(DIST_DIR)/$(ARTIFACT_BASENAME).zip.sha256"
	@echo "Created $(DIST_DIR)/$(ARTIFACT_BASENAME).zip"

dmg: app
	rm -rf "$(DMG_DIR)"
	mkdir -p "$(DMG_DIR)"
	cp -R "$(APP_DIR)" "$(DMG_DIR)/$(APP_NAME).app"
	ln -s /Applications "$(DMG_DIR)/Applications"
	mkdir -p "$(DIST_DIR)"
	rm -f "$(DIST_DIR)/$(ARTIFACT_BASENAME).dmg" "$(DIST_DIR)/$(ARTIFACT_BASENAME).dmg.sha256"
	diskutil image create from --format UDZO --volumeName "$(APP_NAME)" "$(DMG_DIR)" "$(DIST_DIR)/$(ARTIFACT_BASENAME).dmg"
	shasum -a 256 "$(DIST_DIR)/$(ARTIFACT_BASENAME).dmg" > "$(DIST_DIR)/$(ARTIFACT_BASENAME).dmg.sha256"
	@echo "Created $(DIST_DIR)/$(ARTIFACT_BASENAME).dmg"

release-artifacts: zip dmg

clean:
	rm -rf .build "$(BUILD_DIR)" "$(DIST_DIR)"
