# Homebrew passes VERSION explicitly; local builds use the latest tag. Must be X.Y.Z,
# the only form CFBundleShortVersionString allows.
VERSION ?= $(or $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//'),0.0.0)
# Homebrew builds inside its own sandbox, so it passes --disable-sandbox here.
SWIFT_BUILD_FLAGS ?=
APP := build/Keywarp.app

.PHONY: bundle test release clean

bundle:
	@echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' || { echo "VERSION must be X.Y.Z, got \"$(VERSION)\"" >&2; exit 1; }
	swift build -c release $(SWIFT_BUILD_FLAGS)
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp "$$(swift build -c release $(SWIFT_BUILD_FLAGS) --show-bin-path)/keywarp" $(APP)/Contents/MacOS/keywarp
	sed 's/__VERSION__/$(VERSION)/g' Resources/Info.plist > $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

test:
	swift test

release:
	scripts/release.sh "$(VERSION)"

clean:
	rm -rf .build build
