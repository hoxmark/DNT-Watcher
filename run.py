"""Main entry point for DNT Watcher - monitors cabin availability."""

import datetime

from colorama import Fore, Style
from config import extract_cabin_id, load_cabins
from helper import (
    diff_lists,
    extract_available_dates,
    find_available_weekends,
    get_availability,
    load_latest_files,
    print_date_statistics,
    save_result_as_json,
)
from notify import send_notification


def check_cabin_availability(cabin_id: str, cabin_name: str = "Cabin"):
    """
    Check the availability of a cabin based on the cabin ID.

    Args:
        cabin_id (str): The cabin ID (e.g., "101297" for Stallen).
        cabin_name (str): The name of the cabin for display purposes.

    Returns:
        None
    """
    print(f"\n{Fore.CYAN}━━━ {cabin_name} {Fore.WHITE}(ID: {cabin_id}){Fore.CYAN} ━━━{Style.RESET_ALL}")

    # Get availability from today until November of next year
    today = datetime.date.today()
    from_date = today.strftime("%Y-%m-%d")
    next_year = today.year + 1
    to_date = f"{next_year}-11-01"

    # Fetch availability data from API
    result = get_availability(cabin_id, from_date, to_date)
    if not result:
        print(f"{Fore.RED}✗ Failed to fetch availability{Style.RESET_ALL}")
        return

    # Extract available dates
    available = extract_available_dates(result)

    # Display statistics
    print_date_statistics(available)

    # Save results to history
    save_result_as_json(available)

    # Check for new dates compared to previous run
    last_results = load_latest_files()
    if len(last_results) < 2:
        print(f"{Fore.YELLOW}ℹ First run - no history to compare{Style.RESET_ALL}\n")
        return

    # Compare with previous results
    added, removed = diff_lists(last_results[0], last_results[1])

    # Send notifications for new dates
    if added:
        new_weekends = find_available_weekends(added)
        if new_weekends:
            weekend_str = ", ".join([f.strftime("%Y-%m-%d") for f, _ in new_weekends])
            send_notification(
                "DNT Watcher - NEW WEEKENDS!",
                f"{cabin_name}: {len(new_weekends)} new weekend(s)! {weekend_str}",
            )
        else:
            send_notification(
                "DNT Watcher", f"{cabin_name}: {len(added)} new date(s) available"
            )

    print()  # Extra spacing


def main():
    """Main function to run the DNT Watcher."""
    # Load cabin configuration from YAML
    cabins = load_cabins()

    if not cabins:
        print(f"{Fore.RED}✗ No cabins configured in dnt_hytter.yaml{Style.RESET_ALL}")
        return

    # Print header
    print(f"\n{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}")
    print(f"{Fore.GREEN}  🏔  DNT WATCHER - Cabin Availability Monitor  🏔{Style.RESET_ALL}")
    print(f"{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Monitoring {len(cabins)} cabin(s){Style.RESET_ALL}")

    # Check availability for each configured cabin
    for cabin in cabins:
        cabin_id = extract_cabin_id(cabin["url"])
        cabin_name = cabin["navn"]
        check_cabin_availability(cabin_id, cabin_name)

    # Footer
    print(f"{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}")
    print(f"{Fore.GREEN}  ✓ Check complete!{Style.RESET_ALL}")
    print(f"{Fore.GREEN}{'=' * 60}{Style.RESET_ALL}\n")


if __name__ == "__main__":
    # Run once
    main()

    # Uncomment to run on interval:
    # import time
    # INTERVAL = 3600  # 1 hour in seconds
    # print(f"\nRunning continuously every {INTERVAL/3600} hour(s). Press Ctrl+C to stop.\n")
    # while True:
    #     time.sleep(INTERVAL)
    #     main()
