import Cocoa
import UserNotifications
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var statusMenuItem: NSMenuItem!
    private var isChecking = false
    private var lastCheckTime: Date?
    private var availabilityData: [String: CabinAvailability] = [:]
    private var checkTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }

        setupMenuBar()

        // Perform initial check after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.performCheck()
        }

        // Schedule periodic checks every hour (3600 seconds)
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            print("Automatic hourly check triggered")
            self?.performCheck()
        }

        print("Automatic checks scheduled: every hour")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timer
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🏔"
        }

        // Create menu
        menu = NSMenu()

        // Initial placeholder
        statusMenuItem = NSMenuItem(title: "Initializing...", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Rerun check option
        let checkItem = NSMenuItem(title: "Check Now", action: #selector(checkNowClicked), keyEquivalent: "r")
        checkItem.target = self
        menu.addItem(checkItem)

        menu.addItem(NSMenuItem.separator())

        // Open at Login option
        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        // Quit option
        let quitItem = NSMenuItem(title: "Quit DNT Watcher", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func checkNowClicked() {
        performCheck()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func cabinClicked(_ sender: NSMenuItem) {
        guard let urlString = sender.representedObject as? String,
              let url = URL(string: urlString) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            do {
                if sender.state == .off {
                    // Enable login item
                    try service.register()
                    sender.state = .on
                    print("Login item enabled")
                } else {
                    // Disable login item
                    try service.unregister()
                    sender.state = .off
                    print("Login item disabled")
                }
            } catch {
                print("Failed to toggle login item: \(error)")

                // Show alert to user
                let alert = NSAlert()
                alert.messageText = "Login Item Error"
                alert.informativeText = "Failed to change login item setting: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func performCheck() {
        guard !isChecking else {
            print("Check already in progress")
            return
        }

        isChecking = true
        updateStatusDisplay(checking: true)

        // Run check in background
        DispatchQueue.global(qos: .userInitiated).async {
            self.runAvailabilityCheck()

            DispatchQueue.main.async {
                self.isChecking = false
                self.lastCheckTime = Date()
                self.updateStatusDisplay(checking: false)
            }
        }
    }

    private func runAvailabilityCheck() {
        let configLoader = ConfigLoader()
        guard let cabins = configLoader.loadCabins() else {
            print("Failed to load cabins configuration")
            return
        }

        let apiClient = DNTAPIClient()
        let analyzer = AvailabilityAnalyzer()
        let historyManager = HistoryManager()
        let notificationManager = NotificationManager()

        var newData: [String: CabinAvailability] = [:]
        var hasNewWeekends = false
        var newWeekendsText = ""
        var hasNewSaturdays = false
        var totalNewDates = 0

        for cabin in cabins {
            print("Checking \(cabin.name)...")

            guard let availability = apiClient.getAvailability(cabinId: cabin.cabinId) else {
                print("Failed to fetch availability for \(cabin.name)")
                continue
            }

            let availableDates = analyzer.extractAvailableDates(from: availability)
            let weekends = analyzer.findAvailableWeekends(in: availableDates)

            // Load previous data
            let previousDates = historyManager.loadLatestHistory(for: cabin.cabinId)

            // Calculate diff
            let (addedDates, _) = analyzer.diffDates(new: availableDates, old: previousDates)

            // Check for new weekends
            let newWeekends = weekends.filter { weekend in
                addedDates.contains(weekend.friday) &&
                addedDates.contains(weekend.saturday) &&
                addedDates.contains(weekend.sunday)
            }

            // Check for new Saturdays (that aren't part of full weekends)
            let newSaturdays = addedDates.filter { date in
                Calendar.current.component(.weekday, from: date) == 7 // Saturday
            }.filter { saturday in
                !newWeekends.contains { $0.saturday == saturday }
            }

            if !newWeekends.isEmpty {
                hasNewWeekends = true
                let weekendStrings = newWeekends.map { weekend in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    return formatter.string(from: weekend.friday)
                }.joined(separator: ", ")
                newWeekendsText += "\(cabin.name): \(weekendStrings)\n"
            }

            if !newSaturdays.isEmpty && newWeekends.isEmpty {
                hasNewSaturdays = true
            }

            totalNewDates += addedDates.count

            // Save current data
            historyManager.saveHistory(dates: availableDates, for: cabin.cabinId)

            // Construct booking URL
            let bookingURL = "https://hyttebestilling.dnt.no/hytte/\(cabin.cabinId)"

            newData[cabin.name] = CabinAvailability(
                cabinId: cabin.cabinId,
                url: bookingURL,
                dates: availableDates,
                weekends: weekends,
                newWeekends: newWeekends,
                newSaturdays: newSaturdays,
                newDates: addedDates.count
            )
        }

        // Update stored data
        DispatchQueue.main.async {
            self.availabilityData = newData
        }

        // Send notifications
        if hasNewWeekends {
            notificationManager.sendNotification(
                title: "NEW FULL WEEKENDS! 🎉",
                body: newWeekendsText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else if hasNewSaturdays {
            notificationManager.sendNotification(
                title: "NEW SATURDAYS!",
                body: "New Saturday availability detected"
            )
        } else if totalNewDates > 0 {
            notificationManager.sendNotification(
                title: "New Dates Available",
                body: "\(totalNewDates) new date(s) available"
            )
        }
    }

    private func updateStatusDisplay(checking: Bool) {
        guard let button = statusItem.button else { return }

        if checking {
            rebuildMenu(checkingState: "Checking availability...")
            button.title = "🏔⏳"
            return
        }

        // Count totals and check for new items
        let totalWeekends = availabilityData.values.reduce(0) { $0 + $1.weekends.count }
        let hasNewWeekends = availabilityData.values.contains { !$0.newWeekends.isEmpty }
        let hasNewSaturdays = availabilityData.values.contains { !$0.newSaturdays.isEmpty }

        // Update icon based on status
        if hasNewWeekends {
            button.title = "🏔🆕"  // NEW weekends!
        } else if hasNewSaturdays {
            button.title = "🏔✨"  // NEW Saturdays
        } else if totalWeekends > 0 {
            button.title = "🏔✓"  // Has weekends
        } else {
            button.title = "🏔"   // No weekends
        }

        rebuildMenu(checkingState: nil)
    }

    private func rebuildMenu(checkingState: String?) {
        // Remove all items
        menu.removeAllItems()

        if let checking = checkingState {
            // Checking state
            let item = NSMenuItem(title: checking, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"

            // Collect all new weekends and new Saturdays
            var hasNewWeekends = false
            var hasNewSaturdays = false
            var totalWeekends = 0

            for data in availabilityData.values {
                if !data.newWeekends.isEmpty {
                    hasNewWeekends = true
                }
                if !data.newSaturdays.isEmpty {
                    hasNewSaturdays = true
                }
                totalWeekends += data.weekends.count
            }

            // 🆕 NEW WEEKENDS - TOP PRIORITY!
            if hasNewWeekends {
                addBoldHeader("🆕 NEW FULL WEEKENDS!")

                for (name, data) in availabilityData.sorted(by: { $0.key < $1.key }) {
                    if !data.newWeekends.isEmpty {
                        for weekend in data.newWeekends {
                            let weekendStr = "\(dateFormatter.string(from: weekend.friday)) - \(dateFormatter.string(from: weekend.sunday))"
                            let item = NSMenuItem(title: "  🎉 \(name): \(weekendStr)", action: #selector(cabinClicked(_:)), keyEquivalent: "")
                            item.target = self
                            item.representedObject = data.url
                            menu.addItem(item)
                        }
                    }
                }
                menu.addItem(NSMenuItem.separator())
            }

            // 🆕 NEW SATURDAYS (not part of full weekends)
            if hasNewSaturdays {
                addBoldHeader("🆕 NEW SATURDAYS")

                for (name, data) in availabilityData.sorted(by: { $0.key < $1.key }) {
                    if !data.newSaturdays.isEmpty {
                        let saturdayStrs = data.newSaturdays.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
                        let item = NSMenuItem(title: "  📅 \(name): \(saturdayStrs)", action: #selector(cabinClicked(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = data.url
                        menu.addItem(item)
                    }
                }
                menu.addItem(NSMenuItem.separator())
            }

            // ALL WEEKENDS
            if totalWeekends > 0 {
                addBoldHeader("🏔 ALL WEEKENDS (\(totalWeekends))")

                for (name, data) in availabilityData.sorted(by: { $0.key < $1.key }) {
                    if !data.weekends.isEmpty {
                        let weekendStrs = data.weekends.map { weekend in
                            "\(dateFormatter.string(from: weekend.friday))-\(dateFormatter.string(from: weekend.sunday))"
                        }.joined(separator: ", ")

                        let isNew = !data.newWeekends.isEmpty
                        let icon = isNew ? "🆕" : "  "
                        let item = NSMenuItem(title: "\(icon) \(name): \(weekendStrs)", action: #selector(cabinClicked(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = data.url
                        menu.addItem(item)
                    }
                }
                menu.addItem(NSMenuItem.separator())
            }

            // SUMMARY
            if let lastCheck = lastCheckTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                timeFormatter.dateStyle = .none
                let timeItem = NSMenuItem(title: "⏱ Updated: \(timeFormatter.string(from: lastCheck))", action: nil, keyEquivalent: "")
                timeItem.isEnabled = false
                menu.addItem(timeItem)
            }

            let totalDates = availabilityData.values.reduce(0) { $0 + $1.dates.count }
            let summaryItem = NSMenuItem(title: "📊 \(totalWeekends) weekends • \(totalDates) dates", action: nil, keyEquivalent: "")
            summaryItem.isEnabled = false
            menu.addItem(summaryItem)
        }

        // Always add actions at the bottom
        menu.addItem(NSMenuItem.separator())

        let checkItem = NSMenuItem(title: "🔄 Check Now", action: #selector(checkNowClicked), keyEquivalent: "r")
        checkItem.target = self
        menu.addItem(checkItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit DNT Watcher", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addBoldHeader(_ text: String) {
        let headerItem = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false

        let font = NSFont.menuBarFont(ofSize: 0)
        let boldFont = NSFont.boldSystemFont(ofSize: font.pointSize)
        let attrString = NSAttributedString(
            string: text,
            attributes: [.font: boldFont]
        )
        headerItem.attributedTitle = attrString
        menu.addItem(headerItem)
    }
}

struct CabinAvailability {
    let cabinId: String
    let url: String
    let dates: [Date]
    let weekends: [Weekend]
    let newWeekends: [Weekend]
    let newSaturdays: [Date]
    let newDates: Int
}
