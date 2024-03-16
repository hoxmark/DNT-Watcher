import datetime
import time

from helper import (
    diff_lists,
    extract_available_dates,
    get_availability,
    get_months_from_now_out_this_year,
    get_months_to_iterate_over,
    load_latest_files,
    print_date_statistics,
    save_result_as_json,
)
from notify import send_notification


def check_cabin_availability(url):
    """
    Check the availability of a cabin based on the provided URL.

    Args:
        url (str): The URL of the cabin to check.

    Returns:
        None
    """

    # Get the months to iterate over,
    months = get_months_from_now_out_this_year(datetime.datetime.now())

    # Get the availability data for the cabin
    result = get_availability(url, months)

    # Extract the available dates from the result
    available = extract_available_dates(result)

    # Print statistics about the available dates
    print_date_statistics(available)

    # Save the available dates as JSON
    save_result_as_json(available)

    # Load the latest files
    last_results = load_latest_files()
    if len(last_results) < 2 or None:
        return
    # Perform diff on the two lists of results
    new_dates = diff_lists(last_results[0], last_results[1])

    if len(new_dates) > 0:
        send_notification("DNT Watcher", str(new_dates))


if __name__ == "__main__":
    # The cabin I care the most about is this: https://hyttebestilling.dnt.no/hytte/101209#rooms
    # with this url to fetch availability:
    fuglemyrshytta = "https://visbook.dnt.no/api/6516/availability/100976/"
    # check_cabin_availability(fuglemyrshytta)

    interval = 3600  # 1 hour
    while True:
        time.sleep(interval)
        check_cabin_availability(fuglemyrshytta)
        print("-" * 80)
        print("")
