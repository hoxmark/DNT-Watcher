"""Tests for DNT Core package."""

import datetime
import unittest

from dnt_core import extract_available_dates, extract_cabin_id, find_available_weekends


class TestConfig(unittest.TestCase):
    """Test configuration helper functions."""

    def test_extract_cabin_id(self):
        """Test extracting cabin ID from URLs."""
        # Test case 1: Standard URL
        url = "https://hyttebestilling.dnt.no/hytte/101297"
        result = extract_cabin_id(url)
        self.assertEqual(result, "101297")

        # Test case 2: URL with trailing slash
        url = "https://hyttebestilling.dnt.no/hytte/101233402/"
        result = extract_cabin_id(url)
        self.assertEqual(result, "101233402")

        # Test case 3: Another cabin
        url = "https://hyttebestilling.dnt.no/hytte/101209"
        result = extract_cabin_id(url)
        self.assertEqual(result, "101209")


class TestAnalysis(unittest.TestCase):
    """Test analysis functions for availability checking."""

    def test_extract_available_dates_empty(self):
        """Test extracting dates from empty response."""
        availability = {}
        expected_output = []
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)

    def test_extract_available_dates_no_availability(self):
        """Test extracting dates when none are available."""
        availability = {
            "data": {
                "availabilityList": [
                    {
                        "date": "2022-01-01T00:00:00.000Z",
                        "products": [{"available": 0}],
                    },
                    {
                        "date": "2022-01-02T00:00:00.000Z",
                        "products": [{"available": 0}],
                    },
                ]
            }
        }
        expected_output = []
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)

    def test_extract_available_dates_with_availability(self):
        """Test extracting dates when some are available."""
        availability = {
            "data": {
                "availabilityList": [
                    {
                        "date": "2022-01-01T00:00:00.000Z",
                        "products": [{"available": 1}],
                    },
                    {
                        "date": "2022-01-02T00:00:00.000Z",
                        "products": [{"available": 0}],
                    },
                    {
                        "date": "2022-01-03T00:00:00.000Z",
                        "products": [{"available": 1}],
                    },
                ]
            }
        }
        expected_output = [
            "2022-01-01T00:00:00.000Z",
            "2022-01-03T00:00:00.000Z",
        ]
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)

    def test_find_available_weekends_none(self):
        """Test finding weekends when none exist."""
        dates = [
            "2022-01-03T00:00:00.000Z",  # Monday
            "2022-01-04T00:00:00.000Z",  # Tuesday
        ]
        result = find_available_weekends(dates)
        self.assertEqual(result, [])

    def test_find_available_weekends_partial(self):
        """Test finding weekends when only partial weekend available."""
        dates = [
            "2022-01-07T00:00:00.000Z",  # Friday
            "2022-01-08T00:00:00.000Z",  # Saturday (but no Sunday)
        ]
        result = find_available_weekends(dates)
        self.assertEqual(result, [])

    def test_find_available_weekends_complete(self):
        """Test finding weekends when full weekend is available."""
        dates = [
            "2022-01-07T00:00:00.000Z",  # Friday
            "2022-01-08T00:00:00.000Z",  # Saturday
            "2022-01-09T00:00:00.000Z",  # Sunday
        ]
        result = find_available_weekends(dates)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0][0], datetime.datetime(2022, 1, 7))
        self.assertEqual(result[0][1], "Fri-Sun")

    def test_find_available_weekends_multiple(self):
        """Test finding multiple weekends."""
        dates = [
            "2022-01-07T00:00:00.000Z",  # Weekend 1: Friday
            "2022-01-08T00:00:00.000Z",  # Weekend 1: Saturday
            "2022-01-09T00:00:00.000Z",  # Weekend 1: Sunday
            "2022-01-14T00:00:00.000Z",  # Weekend 2: Friday
            "2022-01-15T00:00:00.000Z",  # Weekend 2: Saturday
            "2022-01-16T00:00:00.000Z",  # Weekend 2: Sunday
        ]
        result = find_available_weekends(dates)
        self.assertEqual(len(result), 2)


if __name__ == "__main__":
    unittest.main()
