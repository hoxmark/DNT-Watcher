"""Data analysis functions for cabin availability."""

import datetime
import json
import os


def extract_available_dates(availability: dict):
    """
    Extracts and returns a list of available dates from the given availability dictionary.

    Args:
        availability (dict): A dictionary containing availability data from the API.

    Returns:
        list: A list of available dates in ISO format.

    """
    if not availability or "data" not in availability:
        return []

    available_dates = []
    for day_data in availability["data"]["availabilityList"]:
        # Check if any product is available (available > 0)
        for product in day_data.get("products", []):
            if product.get("available", 0) > 0:
                available_dates.append(day_data["date"])
                break  # Only add the date once even if multiple products available

    return available_dates


def find_available_weekends(dates):
    """
    Finds full weekends (Friday-Sunday) that are available.

    Args:
        dates (list): A list of date strings in ISO format.

    Returns:
        list: A list of tuples containing (friday_date, "Fri-Sun") for each available weekend.
    """
    datetime_dates = [
        datetime.datetime.strptime(date[:10], "%Y-%m-%d") for date in dates
    ]
    date_set = set(datetime_dates)

    weekends = []
    for date in sorted(datetime_dates):
        # Check if this is a Friday (weekday() == 4)
        if date.weekday() == 4:
            saturday = date + datetime.timedelta(days=1)
            sunday = date + datetime.timedelta(days=2)

            # Check if both Saturday and Sunday are also available
            if saturday in date_set and sunday in date_set:
                weekends.append((date, "Fri-Sun"))

    return weekends


def save_result_as_json(result, history_dir: str = "history"):
    """
    Save the result as a JSON file with a human-readable timestamped filename.

    Args:
        result (dict): The result to be saved as JSON.
        history_dir (str): Directory to save history files (default: "history").

    Returns:
        str: The path to the saved file.
    """
    import time

    timestamp = time.strftime("%H-%d-%m-%Y")
    filename = f"{history_dir}/{timestamp}.json"
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        json.dump(result, f)

    return filename


def load_latest_files(history_dir: str = "history"):
    """
    Load the contents of the latest two files in the history folder.

    Args:
        history_dir (str): Directory containing history files (default: "history").

    Returns:
        list: A list of dictionaries containing the contents of the latest files.
              Empty list if fewer than 2 files exist.
    """
    if not os.path.exists(history_dir):
        return []

    files = os.listdir(history_dir)
    if len(files) < 2:
        return []

    latest_files = sorted(files)[-2:]

    results = []
    for file in latest_files:
        file_path = os.path.join(history_dir, file)
        with open(file_path) as f:
            result = json.load(f)
            results.append(result)

    return results


def diff_lists(list1, list2):
    """
    Compare two lists and return added/removed elements.

    Args:
        list1 (list): The first list to compare (older data).
        list2 (list): The second list to compare (newer data).

    Returns:
        tuple: (added_dates, removed_dates) as lists of strings.
    """
    added = list(set(list2) - set(list1))
    removed = list(set(list1) - set(list2))

    return added, removed
