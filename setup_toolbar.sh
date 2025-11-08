#!/bin/bash
# DEPRECATED: This script is for the legacy Python toolbar app.
# Please use the Swift toolbar app instead: swift-toolbar/DNTWatcher.app
#
# To build and run the Swift app:
#   cd swift-toolbar
#   ./build-app.sh
#   open DNTWatcher.app

set -e

echo "⚠️  DEPRECATED: Python toolbar app"
echo ""
echo "This script sets up the legacy Python toolbar app (using rumps)."
echo "We recommend using the native Swift app instead for better performance."
echo ""
echo "Swift app location: swift-toolbar/DNTWatcher.app"
echo ""
read -p "Continue with Python toolbar setup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled. Use the Swift app instead!"
    exit 0
fi

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

echo ""
echo "🎉 Setup complete!"
echo ""
echo "You can now run:"
echo "  uv run dnt-toolbar"
echo ""
echo "Note: The Python toolbar does NOT support notifications."
echo "For notifications, use the Swift app: swift-toolbar/DNTWatcher.app"
