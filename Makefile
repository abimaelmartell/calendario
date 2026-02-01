.PHONY: setup generate build run clean install

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
	@open build/Build/Products/Release/Calendario.app

# Clean build artifacts
clean:
	rm -rf build/
	rm -rf Calendario.xcodeproj

# Install to /Applications
install: build
	cp -r build/Build/Products/Release/Calendario.app /Applications/
	@echo "✓ Installed to /Applications"
