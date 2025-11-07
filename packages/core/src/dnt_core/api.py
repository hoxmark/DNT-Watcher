"""API client for DNT cabin availability data."""

import requests


def get_availability(cabin_id: str, from_date: str, to_date: str):
    """
    Get the availability of a specific cabin from the DNT website.

    Parameters:
    cabin_id (str): The cabin ID (e.g., "101297" for Stallen).
    from_date (str): Start date in YYYY-MM-DD format.
    to_date (str): End date in YYYY-MM-DD format.

    Returns:
    dict: A dictionary containing the availability data, or None on error.
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
    except requests.exceptions.RequestException:
        # Return None on error - let calling code handle error reporting
        return None
