# %%
import subprocess


def send_notification(title, message):
    """
    Sends a notification to the macOS Notification Center.

    Parameters:
    - title (str): The title of the notification.
    - message (str): The message body of the notification.
    """
    apple_script = f'display notification "{message}" with title "{title}"'
    subprocess.run(["osascript", "-e", apple_script])
