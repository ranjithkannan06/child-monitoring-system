#!/bin/bash
set -euo pipefail

# Ensure non-interactive CI environment
export CI=true

echo "Setting up Flutter SDK..."

# Use a local Flutter SDK within the build environment
export FLUTTER_HOME="$PWD/.flutter-sdk"
export PATH="$FLUTTER_HOME/bin:$PATH"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

echo "Flutter version:";
flutter --version || true

echo "Flutter doctor (verbose):";
flutter doctor -v || true

echo "Pre-caching web artifacts...";
flutter precache --web || true

echo "Enabling web support..."
flutter config --enable-web

echo "Fetching dependencies..."
flutter pub get

echo "Building Flutter web (release, verbose)..."
flutter build web --release --no-tree-shake-icons -v

echo "Build completed! Output in build/web/"
