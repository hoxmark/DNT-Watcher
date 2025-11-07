# 🏔 DNT Watcher

> Never miss a cabin weekend! Monitor DNT (Den Norske Turistforening) cabin availability and get instant notifications when full weekends become available.

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)](test_helper.py)

## ✨ Features

- 🎯 **Weekend-Focused**: Automatically detects full Friday-Sunday weekends
- 🎨 **Beautiful CLI**: Colorful, clean output highlighting what matters most
- 📱 **Smart Notifications**: macOS alerts when new weekends or dates become available
- 📊 **Multi-Cabin Monitoring**: Track multiple cabins simultaneously via YAML config
- 📈 **Change Detection**: Compares runs to identify newly available dates
- ⚡ **Fast & Simple**: Single API call, easy YAML configuration

## 🚀 Quick Start

### Installation

**Using `uv` (recommended):**

```bash
# Clone the repository
git clone https://github.com/hoxmark/DNT-Watcher.git
cd DNT-Watcher

# Install dependencies
uv sync

# Run the watcher
uv run python run.py
```

**Using pip:**

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

Just add the booking URL from [hyttebestilling.dnt.no](https://hyttebestilling.dnt.no) - the cabin ID is extracted automatically!

## 📸 Example Output

The CLI is designed to be clean and focused on **weekend availability**:

```
============================================================
  🏔  DNT WATCHER - Cabin Availability Monitor  🏔
============================================================
Monitoring 3 cabin(s)

━━━ Stallen (ID: 101297) ━━━

📊 Total available dates: 64

✗ No full weekends available

📅 Weekday breakdown:
  Mon: 16 | Tue: 22 | Wed: 19 | Thu: 7 | Fri: 0 | Sat: 0 | Sun: 0

📆 Range: 2025-11-11 → 2026-10-29

+ 64 new date(s) available


━━━ Skjennungsvolden (ID: 101233402) ━━━

📊 Total available dates: 115

✓ 2 FULL WEEKEND(S) AVAILABLE:
  • 2026-03-14 (Saturday) - Full Fri-Sun weekend
  • 2026-09-19 (Saturday) - Full Fri-Sun weekend

📅 Weekday breakdown:
  Mon: 22 | Tue: 25 | Wed: 27 | Thu: 21 | Fri: 2 | Sat: 2 | Sun: 16

📆 Range: 2025-11-12 → 2026-10-29

★ NEW FULL WEEKEND(S) AVAILABLE! ★
  • 2026-03-14 (Saturday)
  • 2026-09-19 (Saturday)

============================================================
  ✓ Check complete!
============================================================
```

**Colors in the terminal:**
- 🟢 Green = Full weekends available (the good news!)
- 🔴 Red = No weekends / unavailable
- 🟡 Yellow = Partial availability (Saturdays without full weekends)
- 🔵 Cyan = Informational messages

## 🔄 Continuous Monitoring

Run the watcher on an hourly schedule to catch new availability:

```python
# In run.py, uncomment these lines:
import time
INTERVAL = 3600  # 1 hour in seconds
print(f"\nRunning continuously every {INTERVAL/3600} hour(s). Press Ctrl+C to stop.\n")
while True:
    time.sleep(INTERVAL)
    main()
```

Or set up a cron job:
```bash
# Run every hour
0 * * * * cd /path/to/DNT-Watcher && uv run python run.py
```

## 🎯 Why This Project?

DNT cabins are incredibly popular, especially for weekend trips. Full weekends (Fri-Sun) get booked quickly, and the DNT website doesn't offer weekend-specific notifications. This tool:

1. **Focuses on weekends** - Highlights full Fri-Sun availability
2. **Tracks changes** - Notifies you the moment new dates appear
3. **Monitors multiple cabins** - Check all your favorites at once
4. **Runs automatically** - Set it and forget it

## 🔧 How It Works

1. **Fetch**: Queries DNT API for availability (today → November next year)
2. **Extract**: Parses available dates from API response
3. **Analyze**: Identifies full Fri-Sun weekends
4. **Save**: Stores snapshot in `history/` folder
5. **Compare**: Diffs with previous run to detect changes
6. **Notify**: Sends macOS notification for new weekends/dates

## 🧪 Testing

All functionality is covered by unit tests:

```bash
uv run python -m unittest test_helper.py -v
```

**Tests cover:**
- ✅ Cabin ID extraction from URLs
- ✅ API response parsing
- ✅ Weekend detection (partial, complete, multiple)
- ✅ Configuration loading

## 📁 Project Structure

```
DNT-Watcher/
├── run.py              # Main entry point with colorful CLI
├── config.py           # YAML configuration loader
├── helper.py           # Core logic (API, weekend detection, stats)
├── notify.py           # macOS notification system
├── test_helper.py      # Unit tests (8 tests, all passing)
├── dnt_hytter.yaml     # Cabin configuration
├── pyproject.toml      # Dependencies (uv/pip)
├── README.md           # This file
├── CLAUDE.md           # Developer documentation
└── history/            # Availability history (auto-generated)
```

## 🛠 Requirements

- Python 3.11+
- macOS (for notifications - uses AppleScript)
- Dependencies: `requests`, `pyyaml`, `colorama`

## 📝 License

MIT License - feel free to use and modify!

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.com/claude-code)
- Uses the DNT Hyttebestilling API
- Inspired by the frustration of manually checking cabin availability 😅

---

**Happy cabin hunting! 🏔️⛰️🎿**
