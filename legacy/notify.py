"""Notification system for DNT Watcher (macOS only)."""

import subprocess


def send_notification(title: str, message: str):
    """
    Send a notification to the macOS Notification Center.

    Args:
        title (str): The title of the notification.
        message (str): The message body of the notification.

    Note:
        This function only works on macOS as it uses AppleScript via osascript.
    """
    apple_script = f'display notification "{message}" with title "{title}"'
    subprocess.run(["osascript", "-e", apple_script], check=False)
