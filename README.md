# 🏔 DNT Watcher

> Multi-layered cabin availability monitoring system with native Swift apps for macOS & iOS, CLI, and modular architecture!

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Swift 5.9+](https://img.shields.io/badge/swift-5.9+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![UV Workspace](https://img.shields.io/badge/uv-workspace-orange.svg)](https://docs.astral.sh/uv/)
[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)
[![iOS](https://img.shields.io/badge/platform-iOS%2017%2B-blue.svg)](https://www.apple.com/ios/)

## ✨ Features

### macOS Menu Bar App
- 🚀 **Native Swift Performance**: High-performance status bar integration
- 🎯 **Weekend-First UI**: Prioritizes full Friday-Sunday weekends at the top
- 🆕 **NEW Status Tracking**: Highlights newly available weekends/Saturdays
- 🔗 **One-Click Booking**: Clickable cabin names open booking pages
- 📊 **Smart Icons**: Visual status indicators (🏔🆕 = new weekends!)
- 🔔 **Smart Notifications**: User-friendly permission flow
- ⏰ **Automatic Hourly Checks**: Background refresh
- ⚙️ **Settings Window**: Manage cabins with images (⌘,)

### iOS App
- 📱 **Native SwiftUI App**: Modern iOS experience
- 🆕 **NEW Weekend Detection**: Highlights newly available weekends with badges
- 🏔 **Cabin Images**: Beautiful thumbnails from DNT website
- 🔔 **Background Refresh**: Automatic hourly checks (BGTaskScheduler)
- 🇳🇴 **Norwegian Formatting**: Dates in Norwegian (e.g., "5 des")
- ⚙️ **Rich Settings**: Notification preferences, check interval, clear history
- 📳 **Haptic Feedback**: Tactile feedback for interactions
- 🌓 **Dark Mode Optimized**: Beautiful in both light and dark modes

### Cross-Platform
- 🎨 **Beautiful CLI**: Colorful terminal output for scheduled checks
- 📈 **Change Detection**: Intelligent history-based diffing
- 🏗️ **Modern Architecture**: UV Workspace + Swift Package Manager

## 🏗️ Architecture

This project combines **Python UV Workspace** (for core business logic and CLI) with **native Swift** (for macOS & iOS apps):

```
DNT-Watcher/
├── swift-toolbar/              # Native Swift menu bar app (macOS) ⭐
│   ├── Package.swift
│   ├── Sources/DNTWatcher/
│   └── build-app.sh
├── DNT-watcher/                # Native SwiftUI app (iOS) 📱
│   ├── DNT-watcher.xcodeproj
│   └── DNT-watcher/
│       ├── CabinListView.swift
│       ├── CabinDetailView.swift
│       ├── SettingsView.swift
│       ├── BackgroundTaskManager.swift
│       └── Models/ (Cabin, AvailabilityHistory)
├── packages/                   # Python workspace packages
│   ├── core/                   # Business logic (API, analysis, config)
│   ├── notification/           # Cross-platform notification layer (CLI only)
│   ├── cli/                    # Terminal application
│   └── toolbar-app/            # Legacy Python toolbar (no notifications)
├── dnt_hytter.yaml            # Shared cabin configuration
├── history/                    # Shared availability data (macOS)
└── tests/                      # Test suite
```

### Application Overview

#### 🌟 Swift Menu Bar App (Recommended)
**Location:** `swift-toolbar/`

The native macOS menu bar application with weekend-priority UI:
- **AppDelegate.swift**: Menu bar integration & UI
- **DNTAPIClient.swift**: API client
- **AvailabilityAnalyzer.swift**: Weekend detection & diffing
- **ConfigLoader.swift**: YAML configuration parsing
- **HistoryManager.swift**: Change tracking
- **NotificationManager.swift**: Native macOS notifications

**Performance:**
- 🚀 20x faster startup (<100ms vs 1-2s)
- 💾 2x lower memory (37MB vs 80MB)
- 📦 Self-contained (no Python runtime needed)

**UI Features:**
- 🆕 NEW FULL WEEKENDS section (top priority)
- 🆕 NEW SATURDAYS section
- 🏔 ALL WEEKENDS with date ranges
- 🔗 Clickable cabin names → open booking page
- 📊 Smart status icons (🏔🆕, 🏔✨, 🏔✓, 🏔)

#### 📱 iOS App

**Location:** `DNT-watcher/`

The native iOS application built with SwiftUI and SwiftData:
- **CabinListView.swift**: Main list view with pull-to-refresh
- **CabinDetailView.swift**: Detailed availability view with weekend sections
- **SettingsView.swift**: In-app settings with cabin management
- **BackgroundTaskManager.swift**: BGTaskScheduler integration
- **NotificationManager.swift**: UNUserNotificationCenter integration
- **Models/**: SwiftData models (Cabin, AvailabilityHistory)

**Key Features:**
- 🆕 NEW weekend detection with green badges
- 🏔 Cabin images fetched from DNT website
- 📳 Haptic feedback for interactions
- 🇳🇴 Norwegian date formatting (e.g., "5 des")
- 🔔 Customizable notifications with settings toggle
- ⏰ Background refresh (1h, 2h, 4h, or 6h intervals)
- 🌓 Optimized for dark mode
- 📊 SwiftData persistence for cabins and history

**Settings:**
- Notification preferences (enable/disable)
- Check interval customization
- Clear history option
- Add/Edit/Delete cabins with images
- Enable/disable individual cabins

#### 🐍 Python Packages

**Core Package** (`dnt-core`)
- API client for DNT booking system
- Date extraction & weekend detection
- Configuration management
- History persistence

**CLI Application** (`dnt-cli`)
- Beautiful colorful terminal output
- Scheduled execution via cron
- Entry point: `uv run dnt-watcher`

**Notification Package** (`dnt-notification`)
- Cross-platform notification wrapper
- macOS native + fallback for other platforms

## 🚀 Quick Start

### Prerequisites

- **macOS 13.0+** (for Swift menu bar app)
- **iOS 17.0+** (for iPhone/iPad app)
- **Swift 5.9+** (comes with Xcode Command Line Tools)
- **Xcode 15.0+** (for iOS app development)
- **Python 3.11+** (for CLI)
- **[UV package manager](https://docs.astral.sh/uv/)** - Install: `curl -LsSf https://astral.sh/uv/install.sh | sh`

### Installation

```bash
# Clone the repository
git clone https://github.com/hoxmark/DNT-Watcher.git
cd DNT-Watcher

# Sync Python packages (for CLI)
uv sync

# Build Swift menu bar app (macOS)
cd swift-toolbar
./build-app.sh
cd ..

# Open iOS app in Xcode (iOS)
open DNT-watcher/DNT-watcher.xcodeproj
# Build and run on your iPhone/iPad or simulator
```

### Configuration

Edit `dnt_hytter.yaml` in the root directory:

```yaml
dnt_hytter:
  - navn: "Stallen"
    url: "https://hyttebestilling.dnt.no/hytte/101297"
    beskrivelse: "Østmarka – idyllisk ved Røyrivann"

  - navn: "Skjennungsvolden"
    url: "https://hyttebestilling.dnt.no/hytte/101233402"
    beskrivelse: "Nordmarka – flott beliggenhet"

  - navn: "Fuglemyrhytta"
    url: "https://hyttebestilling.dnt.no/hytte/101209"
    beskrivelse: "Nordmarka – moderne DNT-hytte"
```

## 📱 Usage

### Swift Menu Bar App (Recommended)

Launch the native macOS menu bar app:

```bash
open swift-toolbar/DNTWatcher.app
```

**Features:**
- Appears as 🏔 icon in your menu bar
- Click to see availability status
- New weekends highlighted at top with 🆕 icon
- Click any cabin name to open booking page
- **Automatic hourly checks** (runs in background)
- **Smart notifications** for new weekends/dates (asks permission on first launch)
- Manual "Check Now" button (⌘R)
- **"Open at Login"** toggle (starts automatically when you log in)
- **Settings window** to manage cabins with images (⌘,)
- Initial check on launch

**Menu Structure:**
```
┌─────────────────────────────────────┐
│ 🆕 NEW FULL WEEKENDS!               │  ← Bold header
│   🎉 Stallen: Nov 15 - Nov 17       │  ← Click to book!
├─────────────────────────────────────┤
│ 🏔 ALL WEEKENDS (3)                 │
│ 🆕 Stallen: Nov15-17, Jan3-5        │  ← Click to book!
│    Skjennungsvolden: Dec20-22       │  ← Click to book!
├─────────────────────────────────────┤
│ ⏱ Updated: 7:57 AM                  │
│ 📊 3 weekends • 177 dates           │
├─────────────────────────────────────┤
│ 🔄 Check Now              ⌘R        │
├─────────────────────────────────────┤
│ ✓ Open at Login                     │  ← Toggle
├─────────────────────────────────────┤
│ Quit DNT Watcher          ⌘Q        │
└─────────────────────────────────────┘
```

**Status Icons:**
- 🏔🆕 = **NEW WEEKENDS AVAILABLE!** (grab them fast!)
- 🏔✨ = NEW SATURDAYS available
- 🏔✓ = Has weekends (no new ones)
- 🏔⏳ = Checking availability...
- 🏔 = No weekends available

### iOS App

Launch the native iOS app from Xcode or install on your iPhone/iPad:

**Features:**
- Pull-to-refresh to check availability
- Tap cabin to see detailed weekend view
- Tap gear icon for settings
- Background checks every 1-6 hours (customizable)
- Notifications for new weekends/dates
- Haptic feedback on interactions

**Main Views:**

**Cabin List:**
- Shows all enabled cabins with images
- 🆕 NEW badge for cabins with new weekends
- Weekend count and total dates shown
- Pull down to refresh

**Cabin Detail:**
- 🆕 NEW FULL WEEKENDS section (top, green background)
- 🏔 All Weekends section with Fri-Sun dates
- 📅 All Available Dates in grid layout
- Button to open booking page in Safari

**Settings:**
- Add/Edit/Delete cabins
- Enable/disable individual cabins
- Toggle notifications on/off
- Customize check interval (1h, 2h, 4h, 6h)
- Clear history option
- Cabin images automatically fetched

**Norwegian Formatting:**
- Dates shown as "5 des", "20 nov", etc.
- Weekend labels: "Fre - Søn"

### CLI Mode

Run a single check:
```bash
uv run dnt-watcher
```

The CLI provides colorful output focused on weekend availability:

```
============================================================
  🏔  DNT WATCHER - Cabin Availability Monitor  🏔
============================================================
Monitoring 3 cabin(s)

━━━ Stallen (ID: 101297) ━━━

📊 Total available dates: 64

✓ 2 FULL WEEKEND(S) AVAILABLE:
  • 2026-03-14 (Saturday) - Full Fri-Sun weekend
  • 2026-09-19 (Saturday) - Full Fri-Sun weekend

📅 Weekday breakdown:
  Mon: 16 | Tue: 22 | Wed: 19 | Thu: 7 | Fri: 2 | Sat: 2 | Sun: 16

📆 Range: 2025-11-11 → 2026-10-29

★ NEW FULL WEEKEND(S) AVAILABLE! ★
  • 2026-03-14 (Saturday)
============================================================
```

### Continuous Monitoring

**Option 1: Menu Bar App (Recommended)**
```bash
# Launch once - stays running in background
open swift-toolbar/DNTWatcher.app
```
The app automatically checks every hour. You can also use "Check Now" (⌘R) to manually refresh anytime.

**Option 2: Scheduled CLI Checks with Cron**
```bash
# Add to crontab: Check every hour
0 * * * * cd /path/to/DNT-Watcher && uv run dnt-watcher

# Or check only on Saturday mornings
0 8 * * 6 cd /path/to/DNT-Watcher && uv run dnt-watcher
```

## 🎨 Design Principles

### The Weather Station Metaphor

- **Core Package** = Measurement engine (Python business logic)
- **Swift Menu Bar App** = Dashboard display (native UI, always visible)
- **CLI App** = Scheduled reporter (hourly terminal checks)
- **Notification Layer** = Alarm system (critical alerts)

### DRY Architecture

**Python Core** handles all business logic:
- ✅ API calls
- ✅ Date analysis
- ✅ Weekend detection
- ✅ Configuration loading
- ✅ History management

**Swift App** provides native UI:
- ✅ Menu bar integration
- ✅ Native performance
- ✅ macOS-native notifications
- ✅ Weekend-priority display
- ✅ Clickable booking links

## 🧪 Testing

Run the Python test suite:

```bash
# Run all tests
uv run python -m unittest tests/test_core.py -v

# Or use pytest
uv run pytest tests/ -v
```

**Test coverage:**
- ✅ Cabin ID extraction from URLs
- ✅ API response parsing
- ✅ Weekend detection algorithms
- ✅ Configuration loading
- ✅ Diff comparison logic

**Manual Testing:**
```bash
# Test CLI
uv run dnt-watcher

# Test Swift app
open swift-toolbar/DNTWatcher.app

# Test core package
uv run python -c "from dnt_core import load_cabins; print(load_cabins())"
```

## 🔧 Development

### Building the Swift App

```bash
cd swift-toolbar

# Build release version
./build-app.sh

# Or build debug version
swift build

# Run from command line
.build/debug/DNTWatcher
```

### Swift App Architecture

```swift
AppDelegate
  ├── ConfigLoader → Loads YAML via Yams
  ├── DNTAPIClient → Fetches availability
  ├── AvailabilityAnalyzer → Detects weekends
  ├── HistoryManager → Tracks changes
  └── NotificationManager → Shows alerts
```

### Adding New Cabins

Edit `dnt_hytter.yaml` and add a new entry:

```yaml
dnt_hytter:
  - navn: "New Cabin Name"
    url: "https://hyttebestilling.dnt.no/hytte/CABIN_ID"
    beskrivelse: "Description here"
```

Both the Swift app and CLI will automatically pick up the new cabin.

## 📦 Package Details

### Swift Menu Bar App
**Location:** `swift-toolbar/`
**Dependencies:** Yams (YAML parsing)
**Platform:** macOS 13.0+
**Build:** Swift Package Manager

**Key Features:**
- NSStatusItem integration
- Native UNUserNotificationCenter
- Weekend-first UI with NEW tracking
- Clickable booking links
- Background threading for API calls

### Python Core Package
**Package:** `dnt-core`
**Dependencies:** `requests`, `pyyaml`
**Platform:** Cross-platform

**Exports:**
- `get_availability(cabin_id, from_date, to_date)`
- `extract_available_dates(availability)`
- `find_available_weekends(dates)`
- `load_cabins(config_file)`
- `extract_cabin_id(url)`

### Python CLI Package
**Package:** `dnt-cli`
**Dependencies:** `dnt-core`, `dnt-notification`, `colorama`
**Entry Point:** `uv run dnt-watcher`
**Platform:** Cross-platform

## 📝 API Reference

### DNT Availability Calendar API

**Endpoint:**
```
GET https://hyttebestilling.dnt.no/api/booking/availability-calendar
```

**Parameters:**
- `cabinId`: Cabin ID from booking URL
- `fromDate`: Start date (YYYY-MM-DD)
- `toDate`: End date (YYYY-MM-DD)

**Response:**
```json
{
  "data": {
    "availabilityList": [
      {
        "date": "YYYY-MM-DDTHH:MM:SS.SSSZ",
        "products": [
          {"available": 0}  // 0=unavailable, 1+=available
        ]
      }
    ]
  }
}
```

## 🎯 Why Swift + Python?

**Swift for the UI:**
- ✅ Native macOS performance (20x faster startup)
- ✅ Proper app bundle with Info.plist
- ✅ Native notifications without hacks
- ✅ Lower memory footprint
- ✅ Self-contained distribution

**Python for Business Logic:**
- ✅ Rapid development
- ✅ Rich ecosystem (requests, pyyaml)
- ✅ Cross-platform CLI
- ✅ Easy testing
- ✅ Reusable core logic

## 🔧 Troubleshooting

### Swift App Won't Launch

Make sure you've built the app:
```bash
cd swift-toolbar
./build-app.sh
```

### Config File Not Found

The Swift app searches multiple locations for `dnt_hytter.yaml`:
- Current working directory
- Parent directories (up to 8 levels)
- Bundle resource path

Make sure you run the app from the project root or its parent directory.

### Notifications

**First Launch:**
On first launch, DNT Watcher will request notification permissions using the macOS system prompt. Click **"Allow"** to receive alerts when:
- New full weekends become available
- New Saturday dates appear
- Any new dates are added

If you allow notifications, you'll receive a welcome notification confirming it works: "DNT Watcher Active 🏔"

**Settings Window:**
You can check and manage notification permissions directly in the Settings window (⌘,):
- **Green checkmark** = Notifications enabled
- **Orange bell** = Notifications disabled (click "Open Settings" to enable)
- **Blue bell** = Not configured (click "Enable" to allow)

**System Settings:**
You can also change notification settings in:
1. **System Settings** → **Notifications**
2. Find **"DNTWatcher"** in the list
3. Toggle **"Allow Notifications"** on/off

### UV Sync Issues

If dependency resolution fails:
```bash
rm uv.lock
uv sync
```

## 📚 Documentation

- **[Swift Toolbar Evaluation](docs/swift-toolbar-evaluation.md)** - Performance analysis & comparison
- **[Swift V2 Features](docs/swift-toolbar-v2-features.md)** - Weekend-priority UI details
- **[CLAUDE.md](CLAUDE.md)** - Project overview for Claude Code

## 📝 License

MIT License - feel free to use and modify!

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.com/claude-code)
- Swift Package Manager for dependency management
- UV Workspace pattern from [Astral](https://astral.sh/)
- Uses the DNT Hyttebestilling API
- Inspired by the frustration of manually checking cabin availability 😅

---

**Happy cabin hunting! 🏔️⛰️🎿**
