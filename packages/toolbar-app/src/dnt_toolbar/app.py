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
            "Rerun Check Now",
            rumps.separator,
            "Quit"
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

        # Build status text
        status_lines = [
            f"Last Check: {status['last_check']}",
            f"Total Available: {status['total_dates']} dates",
            f"Full Weekends: {status['weekends']}"
        ]

        # Add cabin names
        if status['cabins']:
            status_lines.append("")
            status_lines.append("Monitored Cabins:")
            for cabin in status['cabins']:
                status_lines.append(f"  • {cabin['navn']}")

        self.status_item.title = "\n".join(status_lines)

        # Update menu bar icon based on weekend availability
        if status['weekends'] > 0:
            self.title = "🏔✓"  # Green checkmark when weekends available
        else:
            self.title = "🏔"

    @rumps.clicked("Rerun Check Now")
    def rerun_check(self, _):
        """Manually trigger a full availability check."""
        # Show notification that check is starting
        rumps.notification(
            title="DNT Watcher",
            subtitle="Starting manual check...",
            message="This may take a few moments"
        )

        # Run the check in a background thread to avoid blocking the UI
        def run_check():
            try:
                self._perform_check()
                # Update the display after check completes
                self.update_status_display()
                rumps.notification(
                    title="DNT Watcher",
                    subtitle="Check complete!",
                    message="Status has been updated"
                )
            except Exception as e:
                print(f"Error during check: {e}")
                rumps.notification(
                    title="DNT Watcher",
                    subtitle="Check failed",
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

    @rumps.clicked("Quit")
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
