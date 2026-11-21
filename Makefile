# Homebrew passes VERSION explicitly; local builds describe the git checkout.
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null | sed 's/^v//')
# Homebrew builds inside its own sandbox, so it passes --disable-sandbox here.
SWIFT_BUILD_FLAGS ?=
APP := build/Keywarp.app

.PHONY: bundle test release clean

bundle:
	@test -n "$(VERSION)" || { echo "VERSION is required" >&2; exit 1; }
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
