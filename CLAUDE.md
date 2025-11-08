# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DNT Watcher is a **multi-layered cabin availability monitoring system** for DNT (Den Norske Turistforening) cabins. It combines a **Python UV Workspace** (for business logic and CLI) with a **native Swift menu bar app** (for macOS UI).

**Key Components:**
1. **Swift Menu Bar App** - Native macOS status bar application (⭐ primary interface)
2. **Python Core Package** - Shared business logic (API, analysis, config)
3. **Python CLI Application** - Terminal interface for scheduled monitoring
4. **Notification Package** - Cross-platform notification layer

The system checks cabin availability via API, detects new available dates, highlights full weekend availability (Fri-Sun), tracks NEW weekends/Saturdays, and provides one-click booking links.

## Architecture Pattern

This project follows a **Hybrid Swift + Python Architecture** with the **Weather Station Metaphor**:

- **Swift Menu Bar App** = Dashboard display (native UI, weekend-first layout, clickable booking)
- **Python Core Package** = Measurement engine (API, analysis, weekend detection, history)
- **Python CLI App** = Scheduled reporter (colorful terminal output, cron-friendly)
- **Notification Layer** = Alarm bell (critical event notifications)

### Key Principle: Best Tool for the Job

**Swift handles the UI:**
- Native macOS performance (20x faster startup)
- Proper app bundle with Info.plist
- Native notifications (UNUserNotificationCenter)
- Weekend-priority UI with clickable booking links
- Self-contained distribution

**Python handles business logic:**
- Available from both Swift app and CLI
- Cross-platform core (can run on any platform)
- Easy testing and rapid development
- Rich ecosystem (requests, pyyaml)

## Project Structure

```
DNT-Watcher/
├── swift-toolbar/              # ⭐ Native Swift menu bar app (RECOMMENDED)
│   ├── Package.swift           # Swift Package Manager config
│   ├── Sources/DNTWatcher/
│   │   ├── main.swift          # App entry point
│   │   ├── AppDelegate.swift   # Menu bar UI & logic
│   │   ├── DNTAPIClient.swift  # API integration
│   │   ├── AvailabilityAnalyzer.swift  # Weekend detection & diffing
│   │   ├── ConfigLoader.swift  # YAML config parsing (via Yams)
│   │   ├── HistoryManager.swift # Change tracking
│   │   ├── NotificationManager.swift # Native notifications
│   │   ├── CabinManager.swift  # Cabin list management (UserDefaults + YAML)
│   │   ├── CabinModel.swift    # Cabin data model (Codable)
│   │   ├── SettingsView.swift  # SwiftUI settings window
│   │   └── ImageFetcher.swift  # Fetches cabin images from booking pages
│   ├── Resources/
│   │   ├── Info.plist          # App bundle metadata (bundle ID: io.hoxmark.DNTWatcher)
│   │   └── AppIcon.icns        # App icon (mountain symbol)
│   ├── build-app.sh            # Build script (creates .app bundle)
│   └── DNTWatcher.app          # Built application (gitignored)
├── packages/                   # Python workspace packages
│   ├── core/                   # Core business logic (Python)
│   │   ├── pyproject.toml
│   │   └── src/dnt_core/
│   │       ├── api.py          # DNT API client
│   │       ├── analysis.py     # Date extraction, weekend detection
│   │       └── config.py       # Configuration loading
│   ├── notification/           # Notification layer
│   │   └── src/dnt_notification/
│   │       └── notify.py       # Cross-platform notifications
│   ├── cli/                    # CLI application
│   │   └── src/dnt_cli/
│   │       └── run.py          # Terminal interface
│   └── toolbar-app/            # Legacy Python toolbar (rumps-based)
│       └── src/dnt_toolbar/
│           └── app.py          # Python menu bar app
├── pyproject.toml              # Workspace root configuration
├── dnt_hytter.yaml             # Shared cabin configuration
├── history/                    # JSON files storing availability history
├── tests/                      # Workspace-level tests
│   └── test_core.py            # Tests for core package
└── .gitignore                  # Excludes .venv, history/, .build/, *.app
```

## Package Responsibilities

### 1. Core Package (`dnt-core`)

**Location:** `packages/core/src/dnt_core/`

**Purpose:** Contains ALL business logic - API calls, data processing, analysis, configuration.

**Dependencies:** `requests`, `pyyaml`

**Modules:**

#### api.py
- `get_availability(cabin_id, from_date, to_date)`: Fetches availability from DNT API
- Returns: Dict with availability data or None on error

#### analysis.py
- `extract_available_dates(availability)`: Parses API response for dates with `available > 0`
- `find_available_weekends(dates)`: Identifies full Friday-Sunday weekends
- `save_result_as_json(result, history_dir)`: Saves to `history/` with timestamp
- `load_latest_files(history_dir)`: Loads two most recent history files
- `diff_lists(list1, list2)`: Compares availability snapshots, returns (added, removed)

#### config.py
- `load_cabins(config_file)`: Loads cabin list from YAML
- `extract_cabin_id(url)`: Extracts cabin ID from booking URL

### 2. Notification Package (`dnt-notification`)

**Location:** `packages/notification/src/dnt_notification/`

**Purpose:** Cross-platform system notifications (currently macOS + fallback).

**Dependencies:** None (stdlib only)

**Modules:**

#### notify.py
- `send_notification(title, message)`: Sends system notification
- macOS: Uses AppleScript via `osascript`
- Other platforms: Prints to console (fallback)

### 3. CLI Application (`dnt-cli`)

**Location:** `packages/cli/src/dnt_cli/`

**Purpose:** Beautiful terminal interface with colorful output.

**Dependencies:** `dnt-core`, `dnt-notification`, `colorama`

**Entry Point:** `dnt-watcher` command

**Modules:**

#### run.py
- `print_date_statistics(dates)`: Colorful terminal output with weekend focus
- `print_diff_results(added, removed, cabin_name)`: Displays changes and sends notifications
- `check_cabin_availability(cabin_id, cabin_name)`: Full check workflow for one cabin
- `main()`: Check all configured cabins
- `run_continuous(interval)`: Run checks on interval (default: 3600s)

**Color Scheme:**
- Green: Full weekends available, new additions
- Red: No weekends, removals
- Yellow: Partial availability (Saturdays without full weekends)
- Cyan: Informational messages

### 4. Swift Menu Bar App (⭐ RECOMMENDED)

**Location:** `swift-toolbar/`

**Purpose:** Native macOS status bar application with weekend-priority UI and one-click booking.

**Dependencies:** Yams (YAML parsing via Swift Package Manager)

**Platform:** macOS 13.0+

**Build:** Swift Package Manager (SPM)

**Modules:**

#### AppDelegate.swift
Main application controller with NSStatusItem integration:
- `applicationDidFinishLaunching()`: Setup menu bar, request notification permissions, initial check
- `setupMenuBar()`: Creates status item and menu structure
- `performCheck()`: Background availability checking with threading
- `runAvailabilityCheck()`: Full workflow - load config, fetch data, analyze, save history, notify
- `updateStatusDisplay()`: Updates menu bar icon (🏔🆕, 🏔✨, 🏔✓, 🏔)
- `rebuildMenu()`: Dynamic menu generation with weekend-first layout
- `cabinClicked()`: Opens booking URL in browser

#### DNTAPIClient.swift
HTTP client for DNT booking API:
- `getAvailability(cabinId:)`: Synchronous API call with URLSession + semaphore
- Returns `AvailabilityResponse` or nil
- Date range: today → November 1st next year

#### AvailabilityAnalyzer.swift
Weekend detection and change tracking:
- `extractAvailableDates(from:)`: Parse API response, filter available dates
- `findAvailableWeekends(in:)`: Identify full Fri-Sun sequences
- `diffDates(new:old:)`: Calculate added/removed dates

#### ConfigLoader.swift
YAML configuration management:
- `loadCabins()`: Parse `dnt_hytter.yaml` via Yams
- Multi-strategy path search (works from .app bundle)
- `extractCabinId(from:)`: Parse cabin ID from URL

#### HistoryManager.swift
JSON-based change tracking:
- `saveHistory(dates:for:)`: Save to `history/HH-DD-MM-YYYY-{cabinId}.json`
- `loadLatestHistory(for:)`: Load most recent history file
- `getHistoryDirectory()`: Multi-strategy path finding

#### NotificationManager.swift
Native macOS notifications:
- `sendNotification(title:body:)`: UNUserNotificationCenter integration
- Immediate delivery
- No AppleScript hacks required

#### CabinManager.swift
ObservableObject for cabin list management:
- `loadCabins()`: Load from UserDefaults (primary) or YAML (fallback)
- `saveCabins()`: Persist to UserDefaults
- `addCabin()`, `updateCabin()`, `deleteCabin()`, `toggleCabin()`: CRUD operations
- `getEnabledCabins()`: Returns enabled cabins in format for availability checks
- `fetchMissingImages()`: Background image fetching for cabins
- Storage: UserDefaults with YAML backward compatibility

#### CabinModel.swift
Codable data model:
- `id: UUID`: Unique identifier
- `name, url, description, isEnabled`: Cabin properties
- `imageURL: String?`: Cached cabin image URL
- `cabinId`: Computed property extracting ID from URL

#### SettingsView.swift
SwiftUI settings window (⌘,):
- Cabin list with 60x60 image thumbnails (AsyncImage)
- Add/Edit/Delete cabin functionality
- Enable/disable toggles for each cabin
- Notification permission management UI
- Real-time validation
- Auto-refresh on window open

#### ImageFetcher.swift
Fetches cabin images from booking pages:
- `fetchImageURL(for:)`: Async web scraping
- Extracts first Cloudinary image URL via regex
- Pattern: `https://res.cloudinary.com/ntb/image/upload/...`
- Singleton pattern for efficiency

**UI Features:**
- 🆕 NEW FULL WEEKENDS section (top priority when available)
- 🆕 NEW SATURDAYS section (new Saturday-only availability)
- 🏔 ALL WEEKENDS section with date ranges
- Clickable cabin names → open booking page via NSWorkspace
- 🎨 Mountain app icon (generated programmatically)
- ⚙️ Settings window (⌘,) with:
  - Cabin image thumbnails
  - Add/Edit/Delete cabins
  - Notification permission toggle
  - "Open at Login" toggle
- 🔔 Smart notification permission flow (macOS system prompt)
- 🔄 Automatic hourly checks
- ⏰ Manual "Check Now" (⌘R)
- Smart status icons:
  - 🏔🆕 = NEW weekends available
  - 🏔✨ = NEW Saturdays available
  - 🏔✓ = Has weekends (no new ones)
  - 🏔⏳ = Checking...
  - 🏔 = No weekends

**Performance:**
- Startup: <100ms (vs 1-2s Python)
- Memory: 37MB (vs 80MB Python)
- Bundle size: ~2MB self-contained

**Building:**
```bash
cd swift-toolbar
./build-app.sh  # Creates DNTWatcher.app
open DNTWatcher.app
```

### 5. Legacy Toolbar App (`dnt-toolbar`) - DEPRECATED

**Location:** `packages/toolbar-app/src/dnt_toolbar/`

**Purpose:** Legacy Python-based macOS menu bar application (replaced by Swift app).

**Dependencies:** `dnt-core`, `rumps` (no longer uses `dnt-notification`)

**Entry Point:** `dnt-toolbar` command

**Platform:** macOS only

**Status:** ⚠️ DEPRECATED - Use Swift app for better performance and notifications

**Modules:**

#### app.py
- `DNTToolbarApp`: Main rumps.App class
- `get_latest_status()`: Loads status from history files
- `update_status_display()`: Updates menu bar display
- `rerun_check()`: Manual check trigger (runs in background thread)
- `_perform_check()`: Core check logic (same as CLI, no colorful output)

**Features:**
- Menu bar icon: 🏔 (normal) or 🏔✓ (weekends available)
- Status menu item: Shows last check time, total dates, weekend count, cabin list
- "Rerun Check Now" button: Manual trigger
- Background threading: Prevents UI blocking

**Limitations:**
- ❌ No notifications (removed to avoid conflicts with Swift app)
- ❌ Slower startup (Python runtime)
- ❌ No settings UI
- ❌ No cabin images
- ⚠️ Recommended to use Swift app instead

## Configuration

### dnt_hytter.yaml

Configure which cabins to monitor:

```yaml
dnt_hytter:
  - navn: "Stallen"
    url: "https://hyttebestilling.dnt.no/hytte/101297"
    beskrivelse: "Description here"

  - navn: "Skjennungsvolden"
    url: "https://hyttebestilling.dnt.no/hytte/101233402"
    beskrivelse: "Description here"
```

The cabin ID is automatically extracted from the URL (the number at the end).

## Development Commands

All development uses UV exclusively. No pip or conda commands needed.

### Setup

```bash
# Initial setup - sync all workspace packages and dependencies
uv sync

# Install additional dev dependencies if needed
uv add --dev <package-name>
```

### Running Applications

```bash
# Swift menu bar app (RECOMMENDED)
open swift-toolbar/DNTWatcher.app

# Build Swift app first if needed
cd swift-toolbar && ./build-app.sh && cd ..

# Python CLI application (one-time check)
uv run dnt-watcher

# Legacy Python toolbar app
uv run dnt-toolbar

# Run CLI in continuous mode
uv run python -c "from dnt_cli.run import run_continuous; run_continuous()"
```

### Testing

```bash
# Run all tests
uv run python -m unittest tests/test_core.py -v

# Run with pytest (if preferred)
uv run pytest tests/ -v

# Test individual packages
uv run python -c "from dnt_core import load_cabins; print(load_cabins())"
uv run python -c "from dnt_notification import send_notification; send_notification('Test', 'Works!')"
```

### Development Workflow

1. Make changes to any package (usually `packages/core/`)
2. Changes automatically available to CLI and Toolbar (via workspace imports)
3. Test immediately: `uv run dnt-watcher`
4. Run tests: `uv run python -m unittest tests/test_core.py -v`
5. No need to reinstall - UV handles it automatically

## API Details

### DNT Availability Calendar API

- **Endpoint**: `https://hyttebestilling.dnt.no/api/booking/availability-calendar`
- **Method**: GET
- **Parameters**:
  - `cabinId`: The cabin ID from the booking URL (e.g., "101297")
  - `fromDate`: Start date in YYYY-MM-DD format
  - `toDate`: End date in YYYY-MM-DD format

**Response Structure**:
```json
{
  "data": {
    "availabilityList": [
      {
        "date": "YYYY-MM-DDTHH:MM:SS.SSSZ",
        "products": [
          {
            "available": 0,  // 0 = unavailable, 1+ = available
            "product": {
              "company_id": 2189,
              "product_id": 62,
              "unit_id": 298
            }
          }
        ]
      }
    ]
  }
}
```

## Core Features

### Weekend Detection

The system automatically identifies full Friday-Sunday weekends:
- Searches for consecutive Fri-Sat-Sun dates
- Highlights weekends in statistics output (CLI) and status display (Toolbar)
- Sends special notifications when new weekends become available

### Change Detection

Compares latest run with previous run:
- Stores availability snapshots in `history/` folder
- Detects newly added dates
- Detects removed dates (cancellations)
- Differentiates between regular dates and full weekends in notifications

### Notifications

Notifications are sent when:
- **New full weekends available**: "DNT Watcher - NEW FULL WEEKENDS!" with weekend dates
- **New Saturdays available** (but not full weekends): "DNT Watcher - NEW SATURDAYS!"
- **New dates available**: "DNT Watcher" with count of new dates

## Data Storage

### History Files

- Location: `history/` directory (workspace root)
- Format: JSON arrays of ISO date strings
- Filename: `HH-DD-MM-YYYY.json` (hours-day-month-year)
- Timestamp: Set in `analysis.py` with `time.strftime("%H-%d-%m-%Y")`
- Purpose: Enables diff comparison between runs
- Shared: Both CLI and Toolbar read/write to same history

## Adding New Packages

To add a new application (e.g., web UI, mobile backend):

1. **Create package directory:**
   ```bash
   mkdir -p packages/new-app/src/dnt_new_app
   ```

2. **Create pyproject.toml:**
   ```toml
   [project]
   name = "dnt-new-app"
   version = "1.0.0"
   dependencies = [
       "dnt-core",          # Import core logic
       "dnt-notification",  # Import notifications
       "your-framework",    # Add your dependencies
   ]
   ```

3. **Add to workspace:**
   ```toml
   # Root pyproject.toml
   [tool.uv.workspace]
   members = [
       "packages/core",
       "packages/notification",
       "packages/cli",
       "packages/toolbar-app",
       "packages/new-app"  # Add here
   ]
   ```

4. **Import core functionality:**
   ```python
   from dnt_core import (
       get_availability,
       extract_available_dates,
       find_available_weekends,
       load_cabins,
       extract_cabin_id,
   )
   from dnt_notification import send_notification
   ```

## Testing

Tests are located in `tests/` at workspace root.

**Test Coverage:**
- Cabin ID extraction from URLs
- API response parsing (empty, no availability, with availability)
- Weekend detection (none, partial, complete, multiple)
- Configuration loading

Run with:
```bash
uv run python -m unittest tests/test_core.py -v
```

## Important Notes

1. **Platform Dependency**: Toolbar app and notifications use AppleScript and only work fully on macOS
2. **API Date Range**: CLI/Toolbar check from today until November 1st of next year
3. **History Requirement**: Need at least 2 runs to detect changes
4. **Cabin Configuration**: All cabins in `dnt_hytter.yaml` are checked on each run
5. **Weekend Definition**: Friday-Sunday (3 consecutive days starting on Friday)
6. **DRY Principle**: Never duplicate business logic - always use imports from `dnt-core`

## Common Tasks

### Run a single check (CLI)
```bash
uv run dnt-watcher
```

### Run continuous monitoring (CLI)
```python
from dnt_cli.run import run_continuous
run_continuous(interval=3600)  # 1 hour
```

### Launch menu bar app
```bash
uv run dnt-toolbar
```

### Add a new cabin to monitor
Edit `dnt_hytter.yaml` and add a new entry with `navn`, `url`, and `beskrivelse`.

### Modify business logic
Edit files in `packages/core/src/dnt_core/`. Changes automatically propagate to CLI and Toolbar.

### Change notification behavior
Edit `packages/notification/src/dnt_notification/notify.py`.

### Customize CLI output
Edit `packages/cli/src/dnt_cli/run.py` - specifically `print_date_statistics()` and `print_diff_results()`.

### Extend toolbar features
Edit `packages/toolbar-app/src/dnt_toolbar/app.py` - modify menu items or add new functionality.
