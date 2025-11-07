# DNT Watcher

Monitor DNT (Den Norske Turistforening) cabin availability and get notified when your favorite cabins become available - especially full weekends!

## Features

- **Multi-Cabin Monitoring**: Configure multiple cabins via YAML
- **Weekend Detection**: Automatically identifies full Friday-Sunday weekends
- **Change Tracking**: Compares availability between runs to detect new dates
- **macOS Notifications**: Get instant alerts when new dates or weekends become available
- **Detailed Statistics**: View availability by weekday and date ranges
- **Simple Configuration**: Easy YAML-based cabin setup

## Quick Start

### Installation

Using `uv` (recommended):

```bash
# Clone the repository
cd DNT-Watcher

# Install dependencies
uv sync

# Run the watcher
uv run python run.py
```

Using pip:

```bash
pip install requests pyyaml colorama
python run.py
```

### Configuration

Edit `dnt_hytter.yaml` to configure which cabins to monitor:

```yaml
dnt_hytter:
  - navn: "Stallen"
    url: "https://hyttebestilling.dnt.no/hytte/101297"
    beskrivelse: "Østmarka – idyllisk ved Røyrivann"

  - navn: "Fuglemyrhytta"
    url: "https://hyttebestilling.dnt.no/hytte/101209"
    beskrivelse: "Nordmarka – moderne DNT-hytte"
```

## Example Output

```
================================================================================
                  DNT Watcher - Monitoring Cabin Availability
================================================================================
Loaded 2 cabin(s) from configuration

Checking availability for Stallen (ID: 101297)...
================================================================================
                                DATE STATISTICS
================================================================================
Earliest date: 2025-11-11 (Tuesday)
Latest date: 2026-11-05 (Thursday)
Total number of dates: 68
Unique dates: 68

--------------------------------------------------------------------------------
                              WEEKDAY DISTRIBUTION
--------------------------------------------------------------------------------
Monday    : 17
Tuesday   : 23
Wednesday : 20
Thursday  : 8
Friday    : 0
Saturday  : 0
Sunday    : 0

================================================================================
                   AVAILABLE FULL WEEKENDS (Friday-Sunday): 0
================================================================================
  No full weekends available
================================================================================
```

## Continuous Monitoring

To run the watcher continuously (e.g., every hour), edit `run.py` and uncomment the interval section:

```python
# Uncomment to run on interval:
import time
INTERVAL = 3600  # 1 hour in seconds
print(f"\nRunning continuously every {INTERVAL/3600} hour(s). Press Ctrl+C to stop.\n")
while True:
    time.sleep(INTERVAL)
    main()
```

## How It Works

1. **Fetch**: Queries the DNT API for availability from today until November of next year
2. **Extract**: Parses available dates from the API response
3. **Analyze**: Identifies full weekends and computes statistics
4. **Save**: Stores availability snapshot in `history/` folder
5. **Compare**: Diffs with previous run to detect new dates
6. **Notify**: Sends macOS notification for new dates/weekends

## Requirements

- Python 3.11+
- macOS (for notifications)
- Dependencies: `requests`, `pyyaml`, `colorama`

## Testing

Run the test suite:

```bash
uv run python -m unittest test_helper.py -v
```

## Project Structure

- `run.py` - Main entry point
- `config.py` - YAML configuration loading
- `helper.py` - Core availability checking logic
- `notify.py` - macOS notification system
- `test_helper.py` - Unit tests
- `dnt_hytter.yaml` - Cabin configuration
- `history/` - Availability history (auto-generated)

## License

MIT License
