import datetime
import unittest

from helper import (
    extract_available_dates,
    get_months_from_now_out_this_year,
    get_months_to_iterate_over,
)


class TestHelper(unittest.TestCase):
    def test_get_months_to_iterate_over(self):
        # Test case 1: Starting from January 2022
        start_date = datetime.datetime(2022, 1, 1)
        expected_output = [
            "2022-01",
            "2022-02",
            "2022-03",
            "2022-04",
            "2022-05",
            "2022-06",
            "2022-07",
            "2022-08",
            "2022-09",
            "2022-10",
        ]
        result = list(get_months_to_iterate_over(start_date))
        self.assertEqual(result, expected_output)

        # Test case 2: Starting from November 2022
        start_date = datetime.datetime(2022, 11, 1)
        expected_output = [
            "2022-11",
            "2022-12",
            "2023-01",
            "2023-02",
            "2023-03",
            "2023-04",
            "2023-05",
            "2023-06",
            "2023-07",
            "2023-08",
            "2023-09",
            "2023-10",
        ]
        result = list(get_months_to_iterate_over(start_date))
        self.assertEqual(result, expected_output)

        # Test case 3: Starting from December 2022
        start_date = datetime.datetime(2022, 12, 1)
        expected_output = [
            "2022-12",
            "2023-01",
            "2023-02",
            "2023-03",
            "2023-04",
            "2023-05",
            "2023-06",
            "2023-07",
            "2023-08",
            "2023-09",
            "2023-10",
        ]
        result = list(get_months_to_iterate_over(start_date))
        self.assertEqual(result, expected_output)

    def test_get_months_from_now_out_this_year(self):
        # Test case 1: Starting from January 2022
        start_date = datetime.datetime(2022, 1, 1)
        expected_output = [
            "2022-01",
            "2022-02",
            "2022-03",
            "2022-04",
            "2022-05",
            "2022-06",
            "2022-07",
            "2022-08",
            "2022-09",
            "2022-10",
            "2022-11",
            "2022-12",
        ]
        result = list(get_months_from_now_out_this_year(start_date))
        self.assertEqual(result, expected_output)

        # Test case 2: Starting from November 2022
        start_date = datetime.datetime(2022, 11, 1)
        expected_output = [
            "2022-11",
            "2022-12",
        ]
        result = list(get_months_from_now_out_this_year(start_date))
        self.assertEqual(result, expected_output)

        # Test case 3: Starting from December 2022
        start_date = datetime.datetime(2022, 12, 1)
        expected_output = [
            "2022-12",
        ]
        result = list(get_months_from_now_out_this_year(start_date))
        self.assertEqual(result, expected_output)

    def test_extract_available_dates(self):
        # Test case 1: Empty availability dictionary
        availability = {}
        expected_output = []
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)

        # Test case 2: Availability dictionary with no available dates
        availability = {
            "2022-01": {
                "items": [
                    {
                        "date": "2022-01-01",
                        "webProducts": [{"availability": {"available": False}}],
                    },
                    {
                        "date": "2022-01-02",
                        "webProducts": [{"availability": {"available": False}}],
                    },
                ]
            }
        }
        expected_output = []
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)

        # Test case 3: Availability dictionary with available dates
        availability = {
            "2022-01": {
                "items": [
                    {
                        "date": "2022-01-01",
                        "webProducts": [{"availability": {"available": True}}],
                    },
                    {
                        "date": "2022-01-02",
                        "webProducts": [{"availability": {"available": False}}],
                    },
                    {
                        "date": "2022-01-03",
                        "webProducts": [{"availability": {"available": True}}],
                    },
                ]
            }
        }
        expected_output = ["2022-01-01", "2022-01-03"]
        result = extract_available_dates(availability)
        self.assertEqual(result, expected_output)


if __name__ == "__main__":
    unittest.main()
