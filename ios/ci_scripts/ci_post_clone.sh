#!/bin/sh
# Xcode Cloud: install Flutter + deps before building the iOS app.
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
git clone https://github.com/flutter/flutter.git -b 3.41.3 --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter precache --ios
flutter pub get
flutter build ios --config-only --release
cd ios && pod install
