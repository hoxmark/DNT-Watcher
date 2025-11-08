#!/bin/bash

set -e

# Change to the directory where this script is located
cd "$(dirname "$0")"

echo "Building DNTWatcher..."
swift build -c release

echo "Creating app bundle..."
APP_NAME="DNTWatcher"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up old bundle
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/DNTWatcher "$MACOS_DIR/"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS_DIR/"

# Copy icon
cp Resources/AppIcon.icns "$RESOURCES_DIR/"

# Create PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "App bundle created: $APP_DIR"
echo "Run with: open $APP_DIR"
