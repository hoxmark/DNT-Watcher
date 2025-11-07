"""Native macOS NSPopover-based Menu Bar Application for DNT Watcher.

This provides the most beautiful and flexible UI using native macOS components.
"""

import datetime
import json
import os
import sys
import objc
from AppKit import (
    NSApplication,
    NSStatusBar,
    NSVariableStatusItemLength,
    NSPopover,
    NSViewController,
    NSView,
    NSTextField,
    NSButton,
    NSColor,
    NSFont,
    NSMakeRect,
    NSImage,
    NSEventTrackingRunLoopMode,
)
from Foundation import NSObject
from PyObjCTools import AppHelper

from dnt_core import (
    extract_available_dates,
    extract_cabin_id,
    find_available_weekends,
    get_availability,
    load_cabins,
    load_latest_files,
    save_result_as_json,
)
from dnt_notification import send_notification


class PopoverViewController(NSViewController):
    """Custom view controller for the popover content."""

    def loadView(self):
        """Create the custom view."""
        # Create main view
        self.view = NSView.alloc().initWithFrame_(NSMakeRect(0, 0, 350, 400))
        self.view.setWantsLayer_(True)
        self.view.layer().setBackgroundColor_(
            NSColor.colorWithRed_green_blue_alpha_(0.95, 0.95, 0.95, 1.0).CGColor()
        )

        y_offset = 350

        # Title
        title = NSTextField.alloc().initWithFrame_(NSMakeRect(20, y_offset, 310, 30))
        title.setStringValue_("🏔 DNT WATCHER")
        title.setBezeled_(False)
        title.setDrawsBackground_(False)
        title.setEditable_(False)
        title.setSelectable_(False)
        title.setFont_(NSFont.boldSystemFontOfSize_(18))
        title.setTextColor_(NSColor.colorWithRed_green_blue_alpha_(0.0, 0.4, 0.8, 1.0))
        title.setAlignment_(1)  # Center alignment
        self.view.addSubview_(title)

        y_offset -= 50

        # Weekend status label
        self.weekend_label = NSTextField.alloc().initWithFrame_(
            NSMakeRect(20, y_offset, 310, 40)
        )
        self.weekend_label.setStringValue_("Loading...")
        self.weekend_label.setBezeled_(False)
        self.weekend_label.setDrawsBackground_(False)
        self.weekend_label.setEditable_(False)
        self.weekend_label.setSelectable_(False)
        self.weekend_label.setFont_(NSFont.systemFontOfSize_(14))
        self.view.addSubview_(self.weekend_label)

        y_offset -= 40

        # Dates status label
        self.dates_label = NSTextField.alloc().initWithFrame_(
            NSMakeRect(20, y_offset, 310, 30)
        )
        self.dates_label.setStringValue_("Loading...")
        self.dates_label.setBezeled_(False)
        self.dates_label.setDrawsBackground_(False)
        self.dates_label.setEditable_(False)
        self.dates_label.setSelectable_(False)
        self.dates_label.setFont_(NSFont.systemFontOfSize_(13))
        self.view.addSubview_(self.dates_label)

        y_offset -= 40

        # Last check label
        self.check_label = NSTextField.alloc().initWithFrame_(
            NSMakeRect(20, y_offset, 310, 25)
        )
        self.check_label.setStringValue_("Last Check: Never")
        self.check_label.setBezeled_(False)
        self.check_label.setDrawsBackground_(False)
        self.check_label.setEditable_(False)
        self.check_label.setSelectable_(False)
        self.check_label.setFont_(NSFont.systemFontOfSize_(11))
        self.check_label.setTextColor_(
            NSColor.colorWithRed_green_blue_alpha_(0.5, 0.5, 0.5, 1.0)
        )
        self.view.addSubview_(self.check_label)

        y_offset -= 50

        # Separator
        separator = NSView.alloc().initWithFrame_(NSMakeRect(20, y_offset, 310, 1))
        separator.setWantsLayer_(True)
        separator.layer().setBackgroundColor_(
            NSColor.colorWithRed_green_blue_alpha_(0.7, 0.7, 0.7, 1.0).CGColor()
        )
        self.view.addSubview_(separator)

        y_offset -= 50

        # Rerun button
        self.rerun_button = NSButton.alloc().initWithFrame_(
            NSMakeRect(75, y_offset, 200, 40)
        )
        self.rerun_button.setTitle_("🔄 Rerun Check Now")
        self.rerun_button.setBezelStyle_(1)  # Rounded
        self.rerun_button.setTarget_(self)
        self.rerun_button.setAction_("rerunCheck:")
        self.view.addSubview_(self.rerun_button)

        y_offset -= 60

        # Quit button
        quit_button = NSButton.alloc().initWithFrame_(NSMakeRect(75, y_offset, 200, 35))
        quit_button.setTitle_("❌ Quit")
        quit_button.setBezelStyle_(1)
        quit_button.setTarget_(self)
        quit_button.setAction_("quitApp:")
        self.view.addSubview_(quit_button)

        # Load initial status
        self.updateStatus()

    def updateStatus(self):
        """Update the status labels."""
        status = self.get_latest_status()

        # Format last check time
        last_check = status['last_check']
        if last_check not in ["Never", "Error", "Unknown"]:
            try:
                check_dt = datetime.datetime.strptime(last_check, "%Y-%m-%d %H:%M")
                now = datetime.datetime.now()
                diff = now - check_dt

                if diff.days > 0:
                    time_ago = f"{diff.days}d ago"
                elif diff.seconds >= 3600:
                    hours = diff.seconds // 3600
                    time_ago = f"{hours}h ago"
                elif diff.seconds >= 60:
                    minutes = diff.seconds // 60
                    time_ago = f"{minutes}m ago"
                else:
                    time_ago = "just now"

                last_check_display = f"{check_dt.strftime('%H:%M')} ({time_ago})"
            except:
                last_check_display = last_check
        else:
            last_check_display = last_check

        # Update weekend label with color
        if status['weekends'] > 0:
            self.weekend_label.setStringValue_(
                f"✅ Full Weekends: {status['weekends']} AVAILABLE!"
            )
            self.weekend_label.setTextColor_(
                NSColor.colorWithRed_green_blue_alpha_(0.0, 0.7, 0.0, 1.0)
            )
        else:
            self.weekend_label.setStringValue_("❌ Full Weekends: None found")
            self.weekend_label.setTextColor_(
                NSColor.colorWithRed_green_blue_alpha_(0.9, 0.0, 0.0, 1.0)
            )

        # Update dates label with color
        if status['total_dates'] > 50:
            color = NSColor.colorWithRed_green_blue_alpha_(0.0, 0.7, 0.0, 1.0)
            icon = "🎉"
        elif status['total_dates'] > 0:
            color = NSColor.colorWithRed_green_blue_alpha_(0.9, 0.7, 0.0, 1.0)
            icon = "📅"
        else:
            color = NSColor.colorWithRed_green_blue_alpha_(0.9, 0.0, 0.0, 1.0)
            icon = "⚠️"

        self.dates_label.setStringValue_(f"{icon} Total Dates: {status['total_dates']}")
        self.dates_label.setTextColor_(color)

        # Update check time
        self.check_label.setStringValue_(f"🕐 Last Check: {last_check_display}")

    def get_latest_status(self):
        """Load the latest saved status from history files."""
        try:
            cabins = load_cabins()
            if not cabins:
                return {"last_check": "Never", "total_dates": 0, "weekends": 0, "cabins": []}

            history_dir = "history"
            if not os.path.exists(history_dir):
                return {"last_check": "Never", "total_dates": 0, "weekends": 0, "cabins": []}

            files = os.listdir(history_dir)
            if not files:
                return {"last_check": "Never", "total_dates": 0, "weekends": 0, "cabins": []}

            latest_file = sorted(files)[-1]
            file_path = os.path.join(history_dir, latest_file)

            timestamp_str = latest_file.replace(".json", "")
            try:
                hour, day, month, year = timestamp_str.split("-")
                last_check = f"{year}-{month}-{day} {hour}:00"
            except ValueError:
                last_check = "Unknown"

            with open(file_path) as f:
                available_dates = json.load(f)

            total_dates = len(available_dates)
            weekends = find_available_weekends(available_dates)

            return {
                "last_check": last_check,
                "total_dates": total_dates,
                "weekends": len(weekends),
                "cabins": cabins
            }

        except Exception as e:
            print(f"Error loading status: {e}")
            return {"last_check": "Error", "total_dates": 0, "weekends": 0, "cabins": []}

    def rerunCheck_(self, sender):
        """Handle rerun check button."""
        self.rerun_button.setEnabled_(False)
        self.rerun_button.setTitle_("⏳ Checking...")

        try:
            self._perform_check()
            self.updateStatus()
            send_notification("DNT Watcher", "✅ Check complete!")
        except Exception as e:
            send_notification("DNT Watcher", f"❌ Check failed: {str(e)}")
        finally:
            self.rerun_button.setEnabled_(True)
            self.rerun_button.setTitle_("🔄 Rerun Check Now")

    def _perform_check(self):
        """Perform the actual availability check."""
        cabins = load_cabins()
        if not cabins:
            raise Exception("No cabins configured")

        for cabin in cabins:
            cabin_id = extract_cabin_id(cabin["url"])
            cabin_name = cabin["navn"]

            today = datetime.date.today()
            from_date = today.strftime("%Y-%m-%d")
            next_year = today.year + 1
            to_date = f"{next_year}-11-01"

            result = get_availability(cabin_id, from_date, to_date)
            if not result:
                print(f"Failed to fetch availability for {cabin_name}")
                continue

            available = extract_available_dates(result)
            save_result_as_json(available)

            last_results = load_latest_files()
            if len(last_results) >= 2:
                added = list(set(last_results[1]) - set(last_results[0]))
                if added:
                    new_weekends = find_available_weekends(added)
                    if new_weekends:
                        weekend_str = ", ".join([f.strftime("%Y-%m-%d") for f, _ in new_weekends])
                        send_notification(
                            "DNT Watcher - NEW FULL WEEKENDS!",
                            f"{cabin_name}: {len(new_weekends)} weekend(s)! {weekend_str}",
                        )
                    else:
                        send_notification(
                            "DNT Watcher",
                            f"{cabin_name}: {len(added)} new date(s) available"
                        )

    def quitApp_(self, sender):
        """Handle quit button."""
        NSApplication.sharedApplication().terminate_(None)


class AppDelegate(NSObject):
    """Application delegate to manage the status item and popover."""

    def applicationDidFinishLaunching_(self, notification):
        """Called when the application finishes launching."""
        # Create status bar item
        self.statusItem = NSStatusBar.systemStatusBar().statusItemWithLength_(
            NSVariableStatusItemLength
        )
        self.statusItem.button().setTitle_("🏔")
        self.statusItem.button().setAction_("togglePopover:")
        self.statusItem.button().setTarget_(self)

        # Create popover
        self.popover = NSPopover.alloc().init()
        self.popover.setBehavior_(1)  # Transient - closes when clicking outside

        # Create and set view controller
        self.viewController = PopoverViewController.alloc().init()
        self.popover.setContentViewController_(self.viewController)

    def togglePopover_(self, sender):
        """Toggle the popover visibility."""
        if self.popover.isShown():
            self.popover.close()
        else:
            self.popover.showRelativeToRect_ofView_preferredEdge_(
                sender.bounds(),
                sender,
                3  # NSRectEdgeMinY - show below the button
            )


def main():
    """Entry point for the native macOS toolbar app."""
    if sys.platform != "darwin":
        print("Error: DNT Toolbar Native only works on macOS")
        sys.exit(1)

    app = NSApplication.sharedApplication()
    delegate = AppDelegate.alloc().init()
    app.setDelegate_(delegate)
    AppHelper.runEventLoop()


if __name__ == "__main__":
    main()
