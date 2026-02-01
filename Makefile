.PHONY: setup generate build run clean install release zip dmg

VERSION ?= 1.0.0
APP_NAME = Calendario
APP_PATH = build/Build/Products/Release/$(APP_NAME).app
RELEASE_DIR = release

# Install xcodegen if needed
setup:
	@which xcodegen > /dev/null || brew install xcodegen
	@echo "✓ Ready to build"

# Generate Xcode project from project.yml
generate:
	xcodegen generate

# Build release binary
build: generate
	xcodebuild -project Calendario.xcodeproj -scheme Calendario -configuration Release -derivedDataPath build

# Build and run
run: build
	@open $(APP_PATH)

# Clean build artifacts
clean:
	rm -rf build/
	rm -rf Calendario.xcodeproj
	rm -rf $(RELEASE_DIR)/

# Install to /Applications
install: build
	cp -r $(APP_PATH) /Applications/
	@echo "✓ Installed to /Applications"

# Create release directory and zip
zip: build
	@mkdir -p $(RELEASE_DIR)
	@cd build/Build/Products/Release && zip -r ../../../../$(RELEASE_DIR)/$(APP_NAME)-$(VERSION).zip $(APP_NAME).app
	@echo "✓ Created $(RELEASE_DIR)/$(APP_NAME)-$(VERSION).zip"

# Create DMG (requires create-dmg: brew install create-dmg)
dmg: build
	@mkdir -p $(RELEASE_DIR)
	@which create-dmg > /dev/null || (echo "Install create-dmg first: brew install create-dmg" && exit 1)
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-size 500 300 \
		--icon-size 100 \
		--icon "$(APP_NAME).app" 125 150 \
		--app-drop-link 375 150 \
		$(RELEASE_DIR)/$(APP_NAME)-$(VERSION).dmg \
		$(APP_PATH)
	@echo "✓ Created $(RELEASE_DIR)/$(APP_NAME)-$(VERSION).dmg"

# Create both zip and dmg
release: zip dmg
	@echo "✓ Release $(VERSION) ready in $(RELEASE_DIR)/"
	@ls -la $(RELEASE_DIR)/
