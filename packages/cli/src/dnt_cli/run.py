"""Main entry point for DNT Watcher CLI - monitors cabin availability with beautiful output."""

import datetime
import sys

from colorama import Fore, Style, init
from dnt_core import (
    diff_lists,
    extract_available_dates,
    extract_cabin_id,
    find_available_weekends,
    get_availability,
    load_cabins,
    load_latest_files,
    save_result_as_json,
)
from dnt_notification import send_notification

# Initialize colorama
init(autoreset=True)


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
        print(f"\n{Fore.YELLOW}📅 {len(saturdays)} Saturday(s) available (but not full weekends):{Style.RESET_ALL}")
        for saturday in saturdays[:5]:  # Show max 5
            print(f"  {Fore.YELLOW}•{Style.RESET_ALL} {saturday.strftime('%Y-%m-%d')}")
        if len(saturdays) > 5:
            print(f"  {Fore.YELLOW}... and {len(saturdays) - 5} more{Style.RESET_ALL}")
    elif saturdays and weekends:
        # Show how many Saturdays are part of full weekends
        non_weekend_saturdays = [s for s in saturdays if s not in [w[0] + datetime.timedelta(days=1) for w in weekends]]
        if non_weekend_saturdays:
            print(f"\n{Fore.YELLOW}📅 {len(non_weekend_saturdays)} additional Saturday(s) (not full weekends):{Style.RESET_ALL}")
            for saturday in non_weekend_saturdays[:3]:
                print(f"  {Fore.YELLOW}•{Style.RESET_ALL} {saturday.strftime('%Y-%m-%d')}")
            if len(non_weekend_saturdays) > 3:
                print(f"  {Fore.YELLOW}... and {len(non_weekend_saturdays) - 3} more{Style.RESET_ALL}")

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


def print_diff_results(added, removed, cabin_name):
    """
    Print comparison results with colorful output and send notifications.

    Args:
        added (list): List of newly added dates.
        removed (list): List of removed dates.
        cabin_name (str): Name of the cabin for notifications.

    Returns:
        None
    """
    if not added and not removed:
        print(f"{Fore.CYAN}ℹ No changes since last check{Style.RESET_ALL}")
        return

    if added:
        # Check if any new dates are full weekends
        added_weekends = find_available_weekends(added)

        # Check if any new dates are Saturdays
        added_dates = [datetime.datetime.strptime(d[:10], "%Y-%m-%d") for d in added]
        added_saturdays = [d for d in added_dates if d.weekday() == 5]

        if added_weekends:
            print(f"{Fore.GREEN}★ NEW FULL WEEKEND(S) AVAILABLE! ★{Style.RESET_ALL}")
            for friday, _ in added_weekends:
                saturday = friday + datetime.timedelta(days=1)
                print(f"  {Fore.GREEN}• {saturday.strftime('%Y-%m-%d')} (Saturday){Style.RESET_ALL}")

            # Send notification for new weekends
            weekend_str = ", ".join([f.strftime("%Y-%m-%d") for f, _ in added_weekends])
            send_notification(
                "DNT Watcher - NEW FULL WEEKENDS!",
                f"{cabin_name}: {len(added_weekends)} weekend(s)! {weekend_str}",
            )
        elif added_saturdays:
            print(f"{Fore.YELLOW}★ NEW SATURDAY(S) AVAILABLE! ★{Style.RESET_ALL}")
            for saturday in added_saturdays[:5]:
                print(f"  {Fore.YELLOW}• {saturday.strftime('%Y-%m-%d')} (Saturday){Style.RESET_ALL}")
            if len(added_saturdays) > 5:
                print(f"  {Fore.YELLOW}... and {len(added_saturdays) - 5} more{Style.RESET_ALL}")

            # Send notification for new Saturdays
            saturday_str = ", ".join([d.strftime("%Y-%m-%d") for d in added_saturdays[:3]])
            if len(added_saturdays) > 3:
                saturday_str += f" +{len(added_saturdays) - 3} more"
            send_notification(
                "DNT Watcher - NEW SATURDAYS!",
                f"{cabin_name}: {len(added_saturdays)} Saturday(s)! {saturday_str}",
            )
        else:
            print(f"{Fore.GREEN}+ {len(added)} new date(s) available{Style.RESET_ALL}")
            send_notification(
                "DNT Watcher", f"{cabin_name}: {len(added)} new date(s) available"
            )

    if removed:
        print(f"{Fore.RED}- {len(removed)} date(s) no longer available{Style.RESET_ALL}")


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

    # Print and send notifications
    print_diff_results(added, removed, cabin_name)

    print()  # Extra spacing


def main():
    """Main function to run the DNT Watcher CLI."""
    # Load cabin configuration from YAML
    cabins = load_cabins()

    if not cabins:
        print(f"{Fore.RED}✗ No cabins configured in dnt_hytter.yaml{Style.RESET_ALL}")
        sys.exit(1)

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


def run_continuous(interval: int = 3600):
    """
    Run the watcher continuously on an interval.

    Args:
        interval (int): Time between checks in seconds (default: 3600 = 1 hour).
    """
    import time

    # Run first check immediately
    main()

    # Run on interval
    print(f"\n{Fore.CYAN}⏰ Running continuously every {interval/3600} hour(s).{Style.RESET_ALL}")
    print(f"{Fore.CYAN}   Press Ctrl+C to stop.{Style.RESET_ALL}\n")

    while True:
        time.sleep(interval)
        main()


if __name__ == "__main__":
    # Run continuous mode by default
    run_continuous()
