import Foundation

struct Weekend {
    let friday: Date
    let saturday: Date
    let sunday: Date
}

class AvailabilityAnalyzer {
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func extractAvailableDates(from response: DNTAPIClient.AvailabilityResponse) -> [Date] {
        var availableDates: [Date] = []

        for item in response.data.availabilityList {
            // Check if any product has availability > 0
            let hasAvailability = item.products.contains { $0.available > 0 }

            if hasAvailability {
                if let date = isoDateFormatter.date(from: item.date) {
                    availableDates.append(date)
                }
            }
        }

        return availableDates.sorted()
    }

    func findAvailableWeekends(in dates: [Date]) -> [Weekend] {
        guard dates.count >= 3 else { return [] }

        var weekends: [Weekend] = []
        let calendar = Calendar.current

        // Convert dates to set for quick lookup
        let dateSet = Set(dates.map { calendar.startOfDay(for: $0) })

        for date in dates {
            let weekday = calendar.component(.weekday, from: date)

            // Check if this is a Friday (weekday == 6 in Calendar with Sunday = 1)
            if weekday == 6 {
                let startOfDay = calendar.startOfDay(for: date)

                // Check for Saturday and Sunday
                guard let saturday = calendar.date(byAdding: .day, value: 1, to: startOfDay),
                      let sunday = calendar.date(byAdding: .day, value: 2, to: startOfDay) else {
                    continue
                }

                if dateSet.contains(saturday) && dateSet.contains(sunday) {
                    weekends.append(Weekend(friday: startOfDay, saturday: saturday, sunday: sunday))
                }
            }
        }

        return weekends
    }

    func diffDates(new: [Date], old: [Date]) -> (added: [Date], removed: [Date]) {
        let calendar = Calendar.current

        let newSet = Set(new.map { calendar.startOfDay(for: $0) })
        let oldSet = Set(old.map { calendar.startOfDay(for: $0) })

        let added = Array(newSet.subtracting(oldSet)).sorted()
        let removed = Array(oldSet.subtracting(newSet)).sorted()

        return (added, removed)
    }
}
