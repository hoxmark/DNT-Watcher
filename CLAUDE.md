# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DNT Watcher is a cabin availability monitoring system for DNT (Den Norske Turistforening) cabins. It checks cabin availability via API, detects new available dates, highlights full weekend availability (Fri-Sun), and sends macOS notifications when new dates or weekends become available.

The system can run once or continuously on an hourly interval, comparing current availability against historical data stored in JSON files.

## Project Structure

```
DNT-Watcher/
├── run.py              # Main entry point - orchestrates the workflow
├── config.py           # YAML configuration loading and cabin ID extraction
├── helper.py           # Core availability checking and data processing
├── notify.py           # macOS notification system
├── test_helper.py      # Unit tests
├── dnt_hytter.yaml     # Cabin configuration file
├── pyproject.toml      # Project dependencies (uv/pip)
├── history/            # JSON files storing historical availability data
└── .gitignore          # Git ignore rules
```

## Core Modules

### run.py
Main orchestration and entry point:
- `check_cabin_availability(cabin_id, cabin_name)`: Checks a single cabin
- `main()`: Loads cabins from YAML and checks all of them
- Workflow: fetch → extract → analyze → save → diff → notify
- Can run once or on interval (commented out by default)

### config.py
Configuration management:
- `load_cabins(config_file)`: Loads cabin list from `dnt_hytter.yaml`
- `extract_cabin_id(url)`: Extracts cabin ID from booking URL

### helper.py
Data processing utilities:
- `get_availability(cabin_id, from_date, to_date)`: Fetches availability from DNT API
- `extract_available_dates(availability)`: Parses API response for dates with `available > 0`
- `find_available_weekends(dates)`: Identifies full Friday-Sunday weekends
- `print_date_statistics(dates)`: Displays formatted statistics including weekends
- `save_result_as_json(result)`: Saves to `history/` with timestamp `HH-DD-MM-YYYY.json`
- `load_latest_files()`: Loads two most recent history files
- `diff_lists(list1, list2)`: Compares availability snapshots

### notify.py
Notification system (macOS only):
- `send_notification(title, message)`: Sends notifications via AppleScript

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

### Setup with uv (Recommended)

```bash
# Sync dependencies and create virtual environment
uv sync

# Run the watcher once for all configured cabins
uv run python run.py

# Run tests
uv run python -m unittest test_helper.py -v
```

### Traditional Python Setup

```bash
# Install dependencies
pip install requests pyyaml colorama

# Run the watcher
python run.py

# Run tests
python -m unittest test_helper.py
```

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

## Features

### Weekend Detection

The system automatically identifies full Friday-Sunday weekends:
- Searches for consecutive Fri-Sat-Sun dates
- Highlights weekends in statistics output
- Sends special notifications when new weekends become available

### Change Detection

Compares latest run with previous run:
- Stores availability snapshots in `history/` folder
- Detects newly added dates
- Detects removed dates (cancellations)
- Differentiates between regular dates and full weekends in notifications

### Notifications

macOS notifications are sent when:
- **New weekends available**: "DNT Watcher - NEW WEEKENDS!" with weekend dates
- **New dates available**: "DNT Watcher" with count of new dates

## Running Continuously

To run the watcher on an hourly interval, edit `run.py` and uncomment:

```python
# Uncomment to run on interval:
import time
INTERVAL = 3600  # 1 hour in seconds
print(f"\nRunning continuously every {INTERVAL/3600} hour(s). Press Ctrl+C to stop.\n")
while True:
    time.sleep(INTERVAL)
    main()
```

## Data Storage

### History Files

- Location: `history/` directory
- Format: JSON arrays of ISO date strings
- Filename: `HH-DD-MM-YYYY.json` (hours-day-month-year)
- Timestamp: Set in `helper.py` with `time.strftime("%H-%d-%m-%Y")`
- Purpose: Enables diff comparison between runs

## Important Notes

1. **Platform Dependency**: Notifications use AppleScript and only work on macOS
2. **API Date Range**: Checks from today until November 1st of next year
3. **History Requirement**: Need at least 2 runs to detect changes
4. **Cabin Configuration**: All cabins in `dnt_hytter.yaml` are checked on each run
5. **Weekend Definition**: Friday-Sunday (3 consecutive days starting on Friday)

## Testing

Tests cover:
- Cabin ID extraction from URLs
- API response parsing (empty, no availability, with availability)
- Weekend detection (none, partial, complete, multiple)

Run with: `uv run python -m unittest test_helper.py -v`
