#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

# Launch the app
open "swift-toolbar/DNTWatcher.app"

echo "DNT Watcher launched!"
echo "Check your menu bar for the 🏔 icon"
echo "Working directory: $(pwd)"
