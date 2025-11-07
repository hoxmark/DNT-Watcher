#!/bin/bash
# Setup script for DNT Toolbar App (macOS)
# This fixes the macOS notification center issue with rumps

set -e

echo "🏔 Setting up DNT Toolbar App for macOS..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script only works on macOS"
    exit 1
fi

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ Error: UV package manager not found"
    echo "   Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Sync workspace
echo "📦 Syncing workspace packages..."
uv sync --all-packages

# Create Info.plist for notifications
PLIST_PATH=".venv/bin/Info.plist"
echo "📝 Setting up notification permissions..."

if [ -f "$PLIST_PATH" ]; then
    echo "   Info.plist already exists"
else
    /usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string "io.hoxmark.dnt-watcher"' "$PLIST_PATH"
    echo "   ✅ Created $PLIST_PATH"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "You can now run:"
echo "  uv run dnt-toolbar"
echo ""
echo "The app will appear in your menu bar with a 🏔 icon."
