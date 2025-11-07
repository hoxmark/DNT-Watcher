"""macOS Menu Bar Application for DNT Watcher.

This app provides:
- Always-visible status in the macOS menu bar
- Quick access to current availability status
- Manual "Rerun Check" button to trigger an immediate check
- Display of last check time
- Summary of weekends and available dates
"""

import datetime
import json
import os
import sys
import threading

import rumps
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


class DNTToolbarApp(rumps.App):
    """macOS Menu Bar Application for DNT Watcher."""

    def __init__(self):
        super(DNTToolbarApp, self).__init__("DNT", "🏔")
        self.menu = [
            "Status",
            rumps.separator,
            "🔄 Rerun Check Now",
            rumps.separator,
            "❌ Quit"
        ]
        self.status_item = self.menu["Status"]
        self.update_status_display()

    def get_latest_status(self):
        """
        Load the latest saved status from history files.

        Returns:
            dict: Dictionary containing status information with keys:
                  - 'last_check': ISO timestamp string or "Never"
                  - 'total_dates': int
                  - 'weekends': int
                  - 'cabins': list of cabin status dicts
        """
        try:
            # Load cabins config
            cabins = load_cabins()
            if not cabins:
                return {
                    "last_check": "Never",
                    "total_dates": 0,
                    "weekends": 0,
                    "cabins": []
                }

            # Get latest history file timestamp
            history_dir = "history"
            if not os.path.exists(history_dir):
                return {
                    "last_check": "Never",
                    "total_dates": 0,
                    "weekends": 0,
                    "cabins": []
                }

            files = os.listdir(history_dir)
            if not files:
                return {
                    "last_check": "Never",
                    "total_dates": 0,
                    "weekends": 0,
                    "cabins": []
                }

            # Get the latest file
            latest_file = sorted(files)[-1]
            file_path = os.path.join(history_dir, latest_file)

            # Parse timestamp from filename (format: HH-DD-MM-YYYY.json)
            timestamp_str = latest_file.replace(".json", "")
            try:
                hour, day, month, year = timestamp_str.split("-")
                last_check = f"{year}-{month}-{day} {hour}:00"
            except ValueError:
                last_check = "Unknown"

            # Load latest availability data
            with open(file_path) as f:
                available_dates = json.load(f)

            # Calculate statistics
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
            return {
                "last_check": "Error",
                "total_dates": 0,
                "weekends": 0,
                "cabins": []
            }

    def update_status_display(self):
        """Update the status menu item with current information."""
        status = self.get_latest_status()

        # Format last check time nicely
        last_check = status['last_check']
        if last_check not in ["Never", "Error", "Unknown"]:
            try:
                # Parse and format as relative time
                from datetime import datetime
                check_dt = datetime.strptime(last_check, "%Y-%m-%d %H:%M")
                now = datetime.now()
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

        # Build beautifully formatted status text
        status_lines = []

        # Header with icon
        status_lines.append("━━━━━━━━━━━━━━━━━━━━━━━")
        status_lines.append("🏔  DNT WATCHER STATUS")
        status_lines.append("━━━━━━━━━━━━━━━━━━━━━━━")
        status_lines.append("")

        # Last check time
        status_lines.append(f"🕐 Last Check: {last_check_display}")
        status_lines.append("")

        # Availability stats with visual indicators
        if status['weekends'] > 0:
            weekend_icon = "✅"
            weekend_text = f"{status['weekends']} AVAILABLE!"
        else:
            weekend_icon = "❌"
            weekend_text = "None found"

        status_lines.append(f"{weekend_icon} Full Weekends: {weekend_text}")

        # Total dates with different icons based on amount
        if status['total_dates'] > 50:
            dates_icon = "🎉"
        elif status['total_dates'] > 0:
            dates_icon = "📅"
        else:
            dates_icon = "⚠️"

        status_lines.append(f"{dates_icon} Total Dates: {status['total_dates']}")

        # Cabin list (more compact)
        if status['cabins']:
            status_lines.append("")
            status_lines.append("━━━━━━━━━━━━━━━━━━━━━━━")
            status_lines.append(f"📍 Monitoring {len(status['cabins'])} cabin(s):")
            status_lines.append("")
            for i, cabin in enumerate(status['cabins'], 1):
                # Shorten cabin names if too long
                name = cabin['navn']
                if len(name) > 20:
                    name = name[:17] + "..."
                status_lines.append(f"  {i}. {name}")

        self.status_item.title = "\n".join(status_lines)

        # Update menu bar icon based on weekend availability
        if status['weekends'] > 0:
            self.title = "🏔✅"  # Green checkmark when weekends available
        elif status['total_dates'] > 0:
            self.title = "🏔📅"  # Calendar when dates available (but no weekends)
        else:
            self.title = "🏔"  # Just mountain when nothing available

    @rumps.clicked("🔄 Rerun Check Now")
    def rerun_check(self, _):
        """Manually trigger a full availability check."""
        # Show notification that check is starting
        rumps.notification(
            title="🏔 DNT Watcher",
            subtitle="🔍 Starting manual check...",
            message="This may take a few moments"
        )

        # Run the check in a background thread to avoid blocking the UI
        def run_check():
            try:
                self._perform_check()
                # Update the display after check completes
                self.update_status_display()
                rumps.notification(
                    title="🏔 DNT Watcher",
                    subtitle="✅ Check complete!",
                    message="Status has been updated"
                )
            except Exception as e:
                print(f"Error during check: {e}")
                rumps.notification(
                    title="🏔 DNT Watcher",
                    subtitle="❌ Check failed",
                    message=str(e)
                )

        thread = threading.Thread(target=run_check)
        thread.daemon = True
        thread.start()

    def _perform_check(self):
        """
        Perform the actual availability check.

        This is the same logic as the CLI's main() function but without
        the colorful terminal output.
        """
        # Load cabin configuration
        cabins = load_cabins()
        if not cabins:
            raise Exception("No cabins configured")

        # Check each cabin
        for cabin in cabins:
            cabin_id = extract_cabin_id(cabin["url"])
            cabin_name = cabin["navn"]

            # Get availability from today until November of next year
            today = datetime.date.today()
            from_date = today.strftime("%Y-%m-%d")
            next_year = today.year + 1
            to_date = f"{next_year}-11-01"

            # Fetch availability data
            result = get_availability(cabin_id, from_date, to_date)
            if not result:
                print(f"Failed to fetch availability for {cabin_name}")
                continue

            # Extract and save available dates
            available = extract_available_dates(result)
            save_result_as_json(available)

            # Check for new dates
            last_results = load_latest_files()
            if len(last_results) >= 2:
                added = list(set(last_results[1]) - set(last_results[0]))
                if added:
                    # Check for new weekends
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

    @rumps.clicked("❌ Quit")
    def quit_app(self, _):
        """Quit the application."""
        rumps.quit_application()


def main():
    """Entry point for the toolbar app."""
    if sys.platform != "darwin":
        print("Error: DNT Toolbar App only works on macOS")
        sys.exit(1)

    app = DNTToolbarApp()
    app.run()


if __name__ == "__main__":
    main()
