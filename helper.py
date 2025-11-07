"""Helper functions for DNT cabin availability checking."""

import datetime
import json
import os
import time

import requests
from colorama import Fore, Style, init

# Initialize colorama
init(autoreset=True)


def get_availability(cabin_id: str, from_date: str, to_date: str):
    """
    Get the availability of a specific cabin from the DNT website.

    Parameters:
    cabin_id (str): The cabin ID (e.g., "101297" for Stallen).
    from_date (str): Start date in YYYY-MM-DD format.
    to_date (str): End date in YYYY-MM-DD format.

    Returns:
    dict: A dictionary containing the availability data.
    """
    url = "https://hyttebestilling.dnt.no/api/booking/availability-calendar"
    params = {
        "cabinId": cabin_id,
        "fromDate": from_date,
        "toDate": to_date
    }

    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error loading availability: {e}")
        return None


def extract_available_dates(availability: dict):
    """
    Extracts and returns a list of available dates from the given availability dictionary.

    Args:
        availability (dict): A dictionary containing availability data from the new API format.

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


def print_date_statistics(dates):
    """
    Prints clean, colorful statistics focused on weekend availability.

    Args:
        dates (list): A list of dates in the format 'YYYY-MM-DD'.

    Returns:
        None
    """
    datetime_dates = [
        datetime.datetime.strptime(date[:10], "%Y-%m-%d") for date in dates
    ]

    if not datetime_dates:
        print(f"\n{Fore.YELLOW}⚠ No available dates found{Style.RESET_ALL}\n")
        return

    # Find weekends
    weekends = find_available_weekends(dates)

    # Count weekday availability
    weekday_counts = {i: 0 for i in range(7)}  # 0=Monday, 6=Sunday
    for date in datetime_dates:
        weekday_counts[date.weekday()] += 1

    # Print summary
    total_dates = len(datetime_dates)
    print(f"\n{Fore.CYAN}📊 Total available dates:{Style.RESET_ALL} {total_dates}")

    # Print weekend availability - THE MOST IMPORTANT PART
    if weekends:
        print(f"\n{Fore.GREEN}✓ {len(weekends)} FULL WEEKEND(S) AVAILABLE:{Style.RESET_ALL}")
        for friday, _ in weekends:
            saturday = friday + datetime.timedelta(days=1)
            sunday = friday + datetime.timedelta(days=2)
            print(f"  {Fore.GREEN}•{Style.RESET_ALL} {Fore.WHITE}{saturday.strftime('%Y-%m-%d')} (Saturday){Style.RESET_ALL} - Full Fri-Sun weekend")
    else:
        print(f"\n{Fore.RED}✗ No full weekends available{Style.RESET_ALL}")

    # Show Saturday availability (even if not full weekends)
    saturdays = [d for d in datetime_dates if d.weekday() == 5]  # Saturday = 5
    if saturdays and not weekends:
        print(f"\n{Fore.YELLOW}⚠ {len(saturdays)} Saturday(s) available (but not full weekends):{Style.RESET_ALL}")
        for saturday in saturdays[:5]:  # Show max 5
            print(f"  {Fore.YELLOW}•{Style.RESET_ALL} {saturday.strftime('%Y-%m-%d')}")
        if len(saturdays) > 5:
            print(f"  {Fore.YELLOW}... and {len(saturdays) - 5} more{Style.RESET_ALL}")

    # Compact weekday summary
    print(f"\n{Fore.CYAN}📅 Weekday breakdown:{Style.RESET_ALL}")
    weekday_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    weekday_summary = " | ".join([
        f"{name}: {Fore.GREEN if weekday_counts[i] > 0 else Fore.RED}{weekday_counts[i]}{Style.RESET_ALL}"
        for i, name in enumerate(weekday_names)
    ])
    print(f"  {weekday_summary}")

    # Date range
    earliest = min(datetime_dates)
    latest = max(datetime_dates)
    print(f"\n{Fore.CYAN}📆 Range:{Style.RESET_ALL} {earliest.strftime('%Y-%m-%d')} → {latest.strftime('%Y-%m-%d')}")
    print()


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
    Compare two lists and return added/removed elements with clean output.

    Args:
        list1 (list): The first list to compare.
        list2 (list): The second list to compare.

    Returns:
        tuple: (added_dates, removed_dates) as lists
    """
    added = list(set(list2) - set(list1))
    removed = list(set(list1) - set(list2))

    if not added and not removed:
        print(f"{Fore.CYAN}ℹ No changes since last check{Style.RESET_ALL}")
    else:
        if added:
            # Check if any new dates are weekends
            added_weekends = find_available_weekends(added)
            if added_weekends:
                print(f"{Fore.GREEN}★ NEW FULL WEEKEND(S) AVAILABLE! ★{Style.RESET_ALL}")
                for friday, _ in added_weekends:
                    saturday = friday + datetime.timedelta(days=1)
                    print(f"  {Fore.GREEN}• {saturday.strftime('%Y-%m-%d')} (Saturday){Style.RESET_ALL}")
            else:
                print(f"{Fore.GREEN}+ {len(added)} new date(s) available{Style.RESET_ALL}")

        if removed:
            print(f"{Fore.RED}- {len(removed)} date(s) no longer available{Style.RESET_ALL}")

    return added, removed
