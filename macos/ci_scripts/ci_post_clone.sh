#!/bin/sh
# Xcode Cloud: install Flutter + deps before building the macOS app.
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
git clone https://github.com/flutter/flutter.git -b 3.41.3 --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter precache --macos
flutter pub get
flutter build macos --config-only --release
cd macos && pod install
