import datetime
import json
import os
import time

import requests


def get_months_to_iterate_over(date: datetime.datetime):
    """
    Get a generator that yields the months to iterate over until it hits any November (11) of this year or next.

    Parameters:
    date (datetime.datetime): The starting date to begin iterating from.

    Yields:
    str: A string representing the year and month in the format "YYYY-MM".

    """
    current_month = date.month
    current_year = date.year
    while True:
        yield f"{current_year}-{current_month:02d}"
        current_month += 1
        if current_month > 12:
            current_month = 1
            current_year += 1
        if current_month == 11:
            break


def get_months_from_now_out_this_year(date: datetime.datetime):
    """
    Get a generator that yields the months from the current month until the end of the current year.

    Parameters:
    date (datetime.datetime): The starting date to begin iterating from.

    Yields:
    str: A string representing the year and month in the format "YYYY-MM".

    """
    current_month = date.month
    current_year = date.year
    while current_year == date.year:
        yield f"{current_year}-{current_month:02d}"
        current_month += 1
        if current_month > 12:
            current_month = 1
            current_year += 1


def get_availability(url: str, months: list):
    """
    Get the availability of a specific cabin from the DNT website.

    Parameters:
    url (str): The URL to the DNT website.
    months (list): A list of strings representing the months to iterate over.

    Returns:
    dict: A dictionary containing the availability of the cabin.
    """
    availability = {}
    for month in months:
        try:
            response = requests.get(f"{url}{month}/")
            response.raise_for_status()
            data = response.json()
            availability[month] = data
        except requests.exceptions.RequestException as e:
            print(f"Error loading availability for {month}: {e}")
    return availability


def extract_available_dates(availability: dict):
    """
    Extracts and returns a list of available dates from the given availability dictionary.

    Args:
        availability (dict): A dictionary containing availability data.

    Returns:
        list: A list of available dates.

    """
    available_dates = []
    for month, data in availability.items():
        for days in data["items"]:
            if days["webProducts"][0]["availability"]["available"]:
                available_dates.append(days["date"])
    return available_dates


def print_date_statistics(dates):
    """
    Prints statistics about a list of dates.

    Args:
        dates (list): A list of dates in the format 'YYYY-MM-DD'.

    Returns:
        None
    """
    datetime_dates = [
        datetime.datetime.strptime(date[:10], "%Y-%m-%d") for date in dates
    ]
    print(datetime_dates)
    print("-" * 30, "Date Statistics", "-" * 30)
    print(f"Earliest date: {min(datetime_dates)}")
    print(f"Latest date: {max(datetime_dates)}")
    print(f"Total number of dates: {len(datetime_dates)}")
    print(f"Unique dates: {len(set(datetime_dates))}")
    print(f"Dates sorted in ascending order: {sorted(datetime_dates)}")

    # Count the number of dates for each week day
    weekdays = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
    ]
    weekday_counts = {weekday: 0 for weekday in weekdays}
    for date in datetime_dates:
        weekday = weekdays[date.weekday()]
        weekday_counts[weekday] += 1

    print("-" * 30, "Weekday Statistics", "-" * 30)
    for weekday, count in weekday_counts.items():
        print(f"{weekday}: {count}")


def save_result_as_json(result):
    """
    Save the result as a JSON file with a human-readable timestamped filename.

    Args:
        result (dict): The result to be saved as JSON.

    Returns:
        None
    """
    timestamp = time.strftime("%H-%d-%m-%Y")
    filename = f"history/{timestamp}.json"
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        json.dump(result, f)


def load_latest_files():
    """
    Load the contents of the latest two files in the history folder.

    Returns:
        A list of dictionaries containing the contents of the latest files.
    """
    # Find the latest two files in the history folder
    history_folder = "history/"
    files = os.listdir(history_folder)
    latest_files = sorted(files)[-2:]

    # Load the contents of the latest files
    results = []
    for file in latest_files:
        file_path = os.path.join(history_folder, file)
        with open(file_path) as f:
            result = json.load(f)
            results.append(result)

    return results


def diff_lists(list1, list2):
    """
    Compare two lists and print the added and removed elements.

    Args:
        list1 (list): The first list to compare.
        list2 (list): The second list to compare.

    Returns:
        None
    """
    added = list(set(list2) - set(list1))
    removed = list(set(list1) - set(list2))

    if not added and not removed:
        print("No change")
    else:
        print("Added dates:")
        for date in added:
            print(date)

        print("Removed dates:")
        for date in removed:
            print(date)

    return added
