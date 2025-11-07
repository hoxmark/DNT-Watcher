"""PyQt6-based macOS Menu Bar Application for DNT Watcher.

This provides a modern, cross-platform toolbar app with rich UI capabilities.
"""

import datetime
import json
import os
import sys
from PyQt6.QtWidgets import (
    QApplication,
    QSystemTrayIcon,
    QMenu,
    QWidgetAction,
    QLabel,
    QVBoxLayout,
    QWidget,
)
from PyQt6.QtGui import QIcon, QPixmap, QAction, QFont
from PyQt6.QtCore import QTimer, Qt

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


class DNTSystemTray:
    """PyQt6 System Tray Application for DNT Watcher."""

    def __init__(self):
        self.app = QApplication(sys.argv)
        self.app.setQuitOnLastWindowClosed(False)

        # Create system tray icon
        self.tray = QSystemTrayIcon()
        self.tray.setIcon(self._create_icon("🏔"))
        self.tray.setToolTip("DNT Watcher")

        # Create menu
        self.menu = QMenu()
        self.setup_menu()

        self.tray.setContextMenu(self.menu)
        self.tray.show()

        # Update status immediately
        self.update_status()

    def _create_icon(self, emoji):
        """
        Create a QIcon from an emoji (simplified version).

        For production, you'd use actual icon files.
        """
        # For now, return a default icon
        # In a real implementation, you'd generate an icon from the emoji
        return QIcon()  # Qt will use a default icon

    def setup_menu(self):
        """Setup the context menu with styled items."""
        # Header
        header = QWidgetAction(self.menu)
        header_label = QLabel("🏔 DNT WATCHER")
        header_label.setStyleSheet("""
            QLabel {
                font-size: 14px;
                font-weight: bold;
                color: #0066CC;
                padding: 8px;
                background-color: #F0F0F0;
            }
        """)
        header_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        header.setDefaultWidget(header_label)
        self.menu.addAction(header)

        self.menu.addSeparator()

        # Status items (will be updated)
        self.weekend_action = QAction("Loading...", self.menu)
        self.weekend_action.setEnabled(False)
        self.menu.addAction(self.weekend_action)

        self.dates_action = QAction("Loading...", self.menu)
        self.dates_action.setEnabled(False)
        self.menu.addAction(self.dates_action)

        self.menu.addSeparator()

        self.check_time_action = QAction("Last Check: Never", self.menu)
        self.check_time_action.setEnabled(False)
        self.menu.addAction(self.check_time_action)

        self.menu.addSeparator()

        # Rerun check action
        rerun_action = QAction("🔄 Rerun Check Now", self.menu)
        rerun_action.triggered.connect(self.rerun_check)
        self.menu.addAction(rerun_action)

        self.menu.addSeparator()

        # Quit action
        quit_action = QAction("❌ Quit", self.menu)
        quit_action.triggered.connect(self.quit_app)
        self.menu.addAction(quit_action)

    def get_latest_status(self):
        """Load the latest saved status from history files."""
        try:
            cabins = load_cabins()
            if not cabins:
                return {
                    "last_check": "Never",
                    "total_dates": 0,
                    "weekends": 0,
                    "cabins": []
                }

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
            return {
                "last_check": "Error",
                "total_dates": 0,
                "weekends": 0,
                "cabins": []
            }

    def update_status(self):
        """Update the menu items with current status."""
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

        # Update weekend status with rich text
        if status['weekends'] > 0:
            self.weekend_action.setText(f"<span style='color: #00AA00; font-weight: bold;'>✅ Full Weekends: {status['weekends']} AVAILABLE!</span>")
        else:
            self.weekend_action.setText(f"<span style='color: #AA0000;'>❌ Full Weekends: None found</span>")

        # Update dates status with rich text
        if status['total_dates'] > 50:
            color = "#00AA00"
            icon = "🎉"
        elif status['total_dates'] > 0:
            color = "#CCAA00"
            icon = "📅"
        else:
            color = "#AA0000"
            icon = "⚠️"

        self.dates_action.setText(f"<span style='color: {color};'>{icon} Total Dates: {status['total_dates']}</span>")

        # Update check time
        self.check_time_action.setText(f"<span style='color: #888888; font-size: 10px;'>🕐 Last Check: {last_check_display}</span>")

        # Update tray icon tooltip
        self.tray.setToolTip(f"DNT Watcher\n{status['weekends']} weekends | {status['total_dates']} dates")

    def rerun_check(self):
        """Manually trigger a check."""
        self.tray.showMessage(
            "DNT Watcher",
            "🔍 Starting manual check...",
            QSystemTrayIcon.MessageIcon.Information,
            2000
        )

        try:
            self._perform_check()
            self.update_status()
            self.tray.showMessage(
                "DNT Watcher",
                "✅ Check complete!",
                QSystemTrayIcon.MessageIcon.Information,
                2000
            )
        except Exception as e:
            self.tray.showMessage(
                "DNT Watcher",
                f"❌ Check failed: {str(e)}",
                QSystemTrayIcon.MessageIcon.Critical,
                3000
            )

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

    def quit_app(self):
        """Quit the application."""
        self.tray.hide()
        self.app.quit()

    def run(self):
        """Run the application."""
        sys.exit(self.app.exec())


def main():
    """Entry point for the PyQt6 toolbar app."""
    if sys.platform != "darwin":
        print("Warning: This app is designed for macOS but will work on other platforms")

    app = DNTSystemTray()
    app.run()


if __name__ == "__main__":
    main()
