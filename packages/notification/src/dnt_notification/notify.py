"""Notification system for DNT Watcher (macOS only)."""

import subprocess
import sys


def send_notification(title: str, message: str):
    """
    Send a notification to the system notification center.

    Args:
        title (str): The title of the notification.
        message (str): The message body of the notification.

    Note:
        Currently supports macOS only using AppleScript.
        Could be extended to support other platforms using:
        - Windows: win10toast or plyer
        - Linux: notify-send or plyer
    """
    if sys.platform == "darwin":
        # macOS using AppleScript
        apple_script = f'display notification "{message}" with title "{title}"'
        subprocess.run(["osascript", "-e", apple_script], check=False)
    else:
        # Fallback for other platforms - just print to console
        print(f"\n[NOTIFICATION] {title}: {message}\n")
