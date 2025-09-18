#!/bin/bash

# Install Flutter dependencies
flutter pub get

# Build Flutter web app for production
flutter build web --release

# The build output will be in build/web/
echo "Build completed! Output in build/web/"
