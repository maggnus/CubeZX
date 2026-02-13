.PHONY: build run dev up clean ios macos

PROJECT = CubeZX.xcodeproj
SCHEME = CubeZX
CONFIGURATION = Debug

# macOS
MACOS_DESTINATION = "platform=macOS"

# iOS Simulator (iPhone 15 Pro by default)
IOS_SIMULATOR = "platform=iOS Simulator,name=iPhone 15 Pro"

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination $(MACOS_DESTINATION) build

run: build
	@killall $(SCHEME) 2>/dev/null || true
	@open "$$(ls -td ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*/Build/Products/Debug/$(SCHEME).app 2>/dev/null | head -1)"

dev: build
	@killall $(SCHEME) 2>/dev/null || true
	@echo "Building and running $(SCHEME) in foreground mode with logging..."
	@"$$(ls -td ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*/Build/Products/Debug/$(SCHEME).app/Contents/MacOS/$(SCHEME) 2>/dev/null | head -1)"

up: build
	@killall $(SCHEME) 2>/dev/null || true
	@echo "Building and running $(SCHEME) in foreground mode with logging..."
	@"$$(ls -td ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*/Build/Products/Debug/$(SCHEME).app/Contents/MacOS/$(SCHEME) 2>/dev/null | head -1)"

macos: run


ios:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination $(IOS_SIMULATOR) build
	xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true
	xcrun simctl install "iPhone 15 Pro" "$$(find ~/Library/Developer/Xcode/DerivedData -name '$(SCHEME).app' -path '*Debug-iphonesimulator*' | head -1)"
	xcrun simctl launch "iPhone 15 Pro" "$$(defaults read "$$(find ~/Library/Developer/Xcode/DerivedData -name '$(SCHEME).app' -path '*Debug-iphonesimulator*' | head -1)/Info.plist" CFBundleIdentifier)"

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(SCHEME)-*

help:
	@echo "Usage:"
	@echo "  make build   - Build for macOS"
	@echo "  make run     - Build and run on macOS (background)"
	@echo "  make dev     - Build and run on macOS (foreground with console logs)"
	@echo "  make up      - Build and run on macOS (foreground with console logs)"
	@echo "  make macos   - Same as 'make run'"
	@echo "  make ios     - Build and run on iOS Simulator"
	@echo "  make clean   - Clean build artifacts"