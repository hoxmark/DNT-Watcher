# DNT Watcher 
This project is a cabin availability checker. It fetches and analyzes the availability of a cabin from a given URL and provides useful statistics about the available dates. It also saves the available dates as a JSON file and performs a diff operation on the latest two results.

if the diff operation finds a new available date, it sends an notificaiton to the user.

## Example

```text
------------------------------ Date Statistics ------------------------------
Earliest date: 2024-03-20 00:00:00
Latest date: 2024-12-18 00:00:00
Total number of dates: 10
Unique dates: 10
Dates sorted in ascending order: [datetime.datetime(2024, 3, 20, 0, 0), datetime.datetime(2024, 3, 21, 0, 0), datetime.datetime(2024, 4, 8, 0, 0), datetime.datetime(2024, 11, 20, 0, 0), datetime.datetime(2024, 11, 26, 0, 0), datetime.datetime(2024, 11, 27, 0, 0), datetime.datetime(2024, 12, 3, 0, 0), datetime.datetime(2024, 12, 4, 0, 0), datetime.datetime(2024, 12, 9, 0, 0), datetime.datetime(2024, 12, 18, 0, 0)]
------------------------------ Weekday Statistics ------------------------------
Monday: 2
Tuesday: 2
Wednesday: 5
Thursday: 1
Friday: 0
Saturday: 0
Sunday: 0

No change
```

## License
This project is licensed under the MIT License - see the LICENSE.md file for details
