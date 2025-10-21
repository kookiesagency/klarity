#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Setup Flutter
echo "Setting up Flutter..."
flutter doctor -v
flutter config --enable-web

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build web
echo "Building web app..."
flutter build web --release

echo "Build complete!"
