import Foundation
import BackgroundTasks
import SwiftData

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let taskIdentifier = "io.hoxmark.DNTWatcher.refresh"

    private init() {}

    // Register the background task handler
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGProcessingTask)
        }
    }

    // Schedule the next background refresh
    func scheduleBackgroundRefresh() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // Load check interval from settings (default: 1 hour)
        let intervalString = UserDefaults.standard.string(forKey: "checkInterval") ?? "Every Hour"
        let interval: TimeInterval
        switch intervalString {
        case "Every 2 Hours":
            interval = 7200
        case "Every 4 Hours":
            interval = 14400
        case "Every 6 Hours":
            interval = 21600
        default:
            interval = 3600 // Every Hour
        }

        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled for ~\(Int(interval/3600)) hour(s) from now")
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    // Handle the background refresh task
    private func handleBackgroundRefresh(task: BGProcessingTask) {
        print("Background refresh task started")

        // Schedule the next refresh
        scheduleBackgroundRefresh()

        // Create a task to perform the availability check
        Task {
            do {
                await performBackgroundCheck()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background check failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        // Set expiration handler
        task.expirationHandler = {
            print("Background task expired")
        }
    }

    // Perform the actual availability check
    private func performBackgroundCheck() async {
        print("Performing background availability check...")

        // Create model container
        let schema = Schema([
            Cabin.self,
            AvailabilityHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        guard let modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Failed to create model container")
            return
        }

        let context = ModelContext(modelContainer)
        let apiClient = DNTAPIClient()
        let analyzer = AvailabilityAnalyzer()

        // Fetch all enabled cabins
        let descriptor = FetchDescriptor<Cabin>(predicate: #Predicate { $0.isEnabled })
        guard let cabins = try? context.fetch(descriptor) else {
            print("Failed to fetch cabins")
            return
        }

        print("Checking \(cabins.count) enabled cabins...")

        for cabin in cabins {
            do {
                // Fetch new availability
                let response = try await apiClient.getAvailability(cabinId: cabin.cabinId)
                let newDates = analyzer.extractAvailableDates(from: response)
                let newWeekends = analyzer.findAvailableWeekends(in: newDates)

                // Load previous history
                let previousHistory = HistoryService.getLatestHistory(for: cabin.cabinId, context: context)
                let oldDates = previousHistory?.availableDates ?? []

                // Calculate differences
                let diff = analyzer.diffDates(new: newDates, old: oldDates)
                let addedDates = diff.added

                // Find new weekends and new Saturdays
                let newWeekendsDetected = findNewWeekends(in: addedDates, analyzer: analyzer)
                let newSaturdays = findNewSaturdays(in: addedDates, existingWeekends: newWeekendsDetected)

                // Send notifications if there are new dates
                if !addedDates.isEmpty {
                    sendNotifications(
                        cabin: cabin,
                        newWeekends: newWeekendsDetected,
                        newSaturdays: newSaturdays,
                        totalNewDates: addedDates.count
                    )
                }

                // Save history
                HistoryService.saveHistory(cabinId: cabin.cabinId, dates: newDates, context: context)
                cabin.lastChecked = Date()

                print("✓ Checked \(cabin.name): \(newDates.count) dates, \(newWeekendsDetected.count) new weekends")

            } catch {
                print("✗ Error checking \(cabin.name): \(error)")
            }
        }

        // Save context
        try? context.save()
        print("Background check complete!")
    }

    private func findNewWeekends(in dates: [Date], analyzer: AvailabilityAnalyzer) -> [Weekend] {
        return analyzer.findAvailableWeekends(in: dates)
    }

    private func findNewSaturdays(in dates: [Date], existingWeekends: [Weekend]) -> [Date] {
        let calendar = Calendar.current
        let weekendSaturdays = Set(existingWeekends.map { $0.saturday })

        return dates.filter { date in
            let weekday = calendar.component(.weekday, from: date)
            let isSaturday = (weekday == 7)
            let isAlreadyInWeekend = weekendSaturdays.contains(calendar.startOfDay(for: date))
            return isSaturday && !isAlreadyInWeekend
        }
    }

    private func sendNotifications(cabin: Cabin, newWeekends: [Weekend], newSaturdays: [Date], totalNewDates: Int) {
        let notificationManager = NotificationManager.shared

        if !newWeekends.isEmpty {
            // NEW FULL WEEKENDS
            let weekendDates = newWeekends.map { formatWeekend($0) }.joined(separator: ", ")
            notificationManager.sendNotification(
                title: "\(cabin.name) - 🆕 NEW FULL WEEKENDS!",
                body: "Available: \(weekendDates)"
            )
        } else if !newSaturdays.isEmpty {
            // NEW SATURDAYS
            let saturdayDates = newSaturdays.map { formatDate($0) }.joined(separator: ", ")
            notificationManager.sendNotification(
                title: "\(cabin.name) - 🆕 NEW SATURDAYS!",
                body: "Available Saturdays: \(saturdayDates)"
            )
        } else if totalNewDates > 0 {
            // NEW DATES
            notificationManager.sendNotification(
                title: "\(cabin.name) - New Availability",
                body: "\(totalNewDates) new date\(totalNewDates == 1 ? "" : "s") available"
            )
        }
    }

    private func formatWeekend(_ weekend: Weekend) -> String {
        return weekend.friday.norwegianShort
    }

    private func formatDate(_ date: Date) -> String {
        return date.norwegianShort
    }
}
