#!/bin/bash
set -euo pipefail

echo "Setting up Flutter SDK..."

# Use a local Flutter SDK within the build environment
export FLUTTER_HOME="$PWD/.flutter-sdk"
export PATH="$FLUTTER_HOME/bin:$PATH"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

echo "Flutter version:"
flutter --version

echo "Enabling web support..."
flutter config --enable-web

echo "Fetching dependencies..."
flutter pub get

echo "Building Flutter web (release)..."
flutter build web --release --no-tree-shake-icons

echo "Build completed! Output in build/web/"
