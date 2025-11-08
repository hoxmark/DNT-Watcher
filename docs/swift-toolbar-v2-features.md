# Swift Toolbar V2 - Weekend-Priority UI

## Major UI Redesign ✨

The Swift toolbar now **prioritizes weekends and Saturdays** with a completely redesigned menu structure and clickable booking links.

## New Features

### 1. Weekend-First Display 🏔

The menu now shows information in order of importance:

1. **🆕 NEW FULL WEEKENDS!** (if any exist)
   - Shows at the very top
   - Lists each new weekend with dates
   - Cabin name is clickable → opens booking page

2. **🆕 NEW SATURDAYS** (if any exist)
   - New Saturdays that aren't part of full weekends
   - Listed with cabin name
   - Clickable to open booking page

3. **🏔 ALL WEEKENDS** (count)
   - Complete list of all available weekends
   - Shows date ranges (e.g., "Nov 11-Nov 13")
   - Marks new ones with 🆕 icon
   - All clickable

4. **Summary** (at bottom)
   - Last update time
   - Total weekends and dates

### 2. Smart Status Bar Icons

The menu bar icon now changes based on availability status:

| Icon | Meaning |
|------|---------|
| 🏔🆕 | **NEW WEEKENDS AVAILABLE!** (highest priority) |
| 🏔✨ | **NEW SATURDAYS AVAILABLE** |
| 🏔✓ | Has weekends (no new ones) |
| 🏔⏳ | Checking availability... |
| 🏔 | No weekends available |

### 3. Clickable Booking Links 🔗

**Every cabin name is now clickable!**
- Click any cabin in the menu
- Opens the booking page in your default browser
- URL format: `https://hyttebestilling.dnt.no/hytte/{cabinId}`

### 4. NEW Status Tracking

The app now tracks which weekends/Saturdays are **newly available** since the last check:
- Compares current availability with previous check
- Highlights NEW items at the top
- Shows 🆕 icon for new weekends in "ALL WEEKENDS" section
- Persists across app restarts via history files

## Menu Structure Example

```
┌─────────────────────────────────────┐
│ 🆕 NEW FULL WEEKENDS!               │  ← Bold header
│   🎉 Stallen: Nov 15 - Nov 17       │  ← Clickable!
│   🎉 Skjennungsvolden: Dec 20-22    │  ← Clickable!
├─────────────────────────────────────┤
│ 🆕 NEW SATURDAYS                    │
│   📅 Fuglemyrhytta: Nov 30, Dec 7   │  ← Clickable!
├─────────────────────────────────────┤
│ 🏔 ALL WEEKENDS (5)                 │
│ 🆕 Stallen: Nov15-17, Jan3-5        │  ← Clickable!
│    Skjennungsvolden: Dec20-22       │  ← Clickable!
├─────────────────────────────────────┤
│ ⏱ Updated: 7:57 AM                  │
│ 📊 5 weekends • 177 dates           │
├─────────────────────────────────────┤
│ 🔄 Check Now              ⌘R        │
├─────────────────────────────────────┤
│ Quit DNT Watcher          ⌘Q        │
└─────────────────────────────────────┘
```

## Technical Implementation

### Data Structure Changes

**Updated `CabinAvailability` struct:**
```swift
struct CabinAvailability {
    let cabinId: String          // For constructing URLs
    let url: String              // Booking page URL
    let dates: [Date]            // All available dates
    let weekends: [Weekend]      // All full weekends
    let newWeekends: [Weekend]   // ← NEW: Weekends that just appeared
    let newSaturdays: [Date]     // ← NEW: New Saturdays (non-weekend)
    let newDates: Int            // Total new dates
}
```

### Change Detection Algorithm

1. **Load previous check** from history files
2. **Fetch current availability** from API
3. **Diff dates** (new - old = added dates)
4. **Filter new weekends**: Full weekends where all 3 days are in `addedDates`
5. **Filter new Saturdays**: Saturdays in `addedDates` that aren't part of new full weekends
6. **Store results** in `CabinAvailability` for UI display

### URL Opening

When user clicks a cabin:
```swift
@objc private func cabinClicked(_ sender: NSMenuItem) {
    guard let urlString = sender.representedObject as? String,
          let url = URL(string: urlString) else {
        return
    }
    NSWorkspace.shared.open(url)
}
```

The URL is stored in `representedObject` of each menu item.

## User Experience Improvements

### Before
- Cramped single-line text: "Last check: 07:50 Total dates: 177 Full weekends: 0 Cabins: • Fuglemyrhytta..."
- No way to know what's NEW
- No way to book directly
- Hard to scan for weekends

### After
- ✅ **NEW items shown first** (you immediately see new opportunities)
- ✅ **Weekend-focused** (most important info at top)
- ✅ **One-click booking** (click cabin name → opens browser)
- ✅ **Visual status indicators** (🆕, 🎉, icons tell the story)
- ✅ **Clean hierarchy** (bold headers, proper sections)
- ✅ **Scannable dates** ("Nov 15-17" format)

## Notification Behavior

Notifications still work as before:
- **NEW FULL WEEKENDS! 🎉** - Lists cabin names and weekend dates
- **NEW SATURDAYS!** - Indicates new Saturday availability
- **New Dates Available** - General notification for other new dates

## Testing the NEW Status

To see the NEW status indicators in action:

1. **Run the app** (creates initial history)
2. **Wait for a real availability change** OR
3. **Delete history files** to simulate first run
4. **Manually trigger check** (⌘R or "Check Now")
5. Look for 🆕 icons in the menu

## Files Modified

- `swift-toolbar/Sources/DNTWatcher/AppDelegate.swift`
  - Updated `CabinAvailability` struct
  - Added `cabinClicked(_:)` action handler
  - Rewrote `rebuildMenu(checkingState:)` function
  - Added `addBoldHeader(_:)` helper
  - Updated `updateStatusDisplay(checking:)` for new icons
  - Updated `runAvailabilityCheck()` to track new items

## Future Enhancements

Possible improvements:
- [ ] Sound alert for new weekends
- [ ] Periodic auto-check (every hour)
- [ ] Weekend detail view (show all 3 dates)
- [ ] Filter by specific cabins
- [ ] Export weekend list to calendar
- [ ] Historical trend view

## Build & Run

```bash
# Build
swift-toolbar/build-app.sh

# Run
open swift-toolbar/DNTWatcher.app
```

Check your menu bar for the 🏔 icon, then click it to see the beautiful new weekend-focused UI!
