# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DNT Watcher is a **multi-layered cabin availability monitoring system** for DNT (Den Norske Turistforening) cabins. It uses a **UV Workspace architecture** with separated concerns across four packages:

1. **Core Package** - Shared business logic (API, analysis, config)
2. **Notification Package** - Cross-platform notification layer
3. **CLI Application** - Beautiful terminal interface for monitoring
4. **Toolbar App** - macOS menu bar application

The system checks cabin availability via API, detects new available dates, highlights full weekend availability (Fri-Sun), and sends notifications when new dates or weekends become available.

## Architecture Pattern

This project follows the **UV Workspace** pattern with the **Weather Station Metaphor**:

- **Core Package** = Centralized measurement engine (calculates cabin availability, weekend status)
- **CLI App** = Scheduled report generator (colorful terminal output, hourly checks)
- **Notification Package** = Alarm bell (critical event notifications)
- **Toolbar App** = Dashboard display (always-on status, manual check trigger)

### Key Principle: DRY (Don't Repeat Yourself)

ALL business logic lives in the `dnt-core` package. The CLI and Toolbar apps are thin presentation layers that import and use core functionality. Never duplicate business logic across packages.

## Project Structure

```
DNT-Watcher/
├── pyproject.toml              # Workspace root configuration
├── dnt_hytter.yaml             # Shared cabin configuration
├── history/                    # JSON files storing availability history
├── tests/                      # Workspace-level tests
│   └── test_core.py            # Tests for core package
├── packages/
│   ├── core/                   # Core business logic package
│   │   ├── pyproject.toml
│   │   └── src/dnt_core/
│   │       ├── __init__.py
│   │       ├── api.py          # DNT API client
│   │       ├── analysis.py     # Date extraction, weekend detection, diffing
│   │       └── config.py       # Configuration loading
│   ├── notification/           # Notification layer
│   │   ├── pyproject.toml
│   │   └── src/dnt_notification/
│   │       ├── __init__.py
│   │       └── notify.py       # Cross-platform notifications
│   ├── cli/                    # CLI application
│   │   ├── pyproject.toml
│   │   └── src/dnt_cli/
│   │       ├── __init__.py
│   │       └── run.py          # Main CLI entry point
│   └── toolbar-app/            # macOS menu bar app
│       ├── pyproject.toml
│       └── src/dnt_toolbar/
│           ├── __init__.py
│           └── app.py          # Menu bar application
└── .gitignore                  # Excludes .venv, history/, etc.
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

### 4. Toolbar App (`dnt-toolbar`)

**Location:** `packages/toolbar-app/src/dnt_toolbar/`

**Purpose:** macOS menu bar application for persistent monitoring.

**Dependencies:** `dnt-core`, `dnt-notification`, `rumps`

**Entry Point:** `dnt-toolbar` command

**Platform:** macOS only

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
# Run CLI application once
uv run dnt-watcher

# Launch macOS toolbar app
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
