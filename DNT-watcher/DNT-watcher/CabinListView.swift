import SwiftUI
import SwiftData

struct CabinListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cabin.name) private var cabins: [Cabin]
    @State private var availabilityData: [UUID: CabinAvailability] = [:]
    @State private var isLoading = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                if cabins.isEmpty {
                    emptyStateView
                } else {
                    cabinsList
                }
            }
            .navigationTitle("DNT Watcher")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await checkAllCabins()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .refreshable {
                await checkAllCabins()
            }
            .task {
                // Populate default cabins on first launch
                DefaultCabins.populateIfNeeded(modelContext: modelContext)

                // Check on first load if we have cabins
                if !cabins.isEmpty && availabilityData.isEmpty {
                    await checkAllCabins()
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text("No Cabins Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Add cabins in settings to start monitoring availability")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showingSettings = true
            } label: {
                Label("Add Cabins", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var cabinsList: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            }

            ForEach(cabins.filter { $0.isEnabled }) { cabin in
                NavigationLink {
                    CabinDetailView(cabin: cabin, availability: availabilityData[cabin.id])
                } label: {
                    CabinRow(cabin: cabin, availability: availabilityData[cabin.id])
                }
            }
        }
    }

    private func checkAllCabins() async {
        isLoading = true
        defer { isLoading = false }

        let apiClient = DNTAPIClient()
        let analyzer = AvailabilityAnalyzer()

        for cabin in cabins where cabin.isEnabled {
            do {
                // Fetch new availability
                let response = try await apiClient.getAvailability(cabinId: cabin.cabinId)
                let newDates = analyzer.extractAvailableDates(from: response)
                let newWeekends = analyzer.findAvailableWeekends(in: newDates)

                // Load previous history
                let previousHistory = await MainActor.run {
                    HistoryService.getLatestHistory(for: cabin.cabinId, context: modelContext)
                }
                let oldDates = previousHistory?.availableDates ?? []

                // Calculate differences
                let diff = analyzer.diffDates(new: newDates, old: oldDates)
                let addedDates = diff.added

                // Find new weekends and new Saturdays
                let newWeekendsDetected = findNewWeekends(in: addedDates, analyzer: analyzer)
                let newSaturdays = findNewSaturdays(in: addedDates, existingWeekends: newWeekendsDetected)

                // Send notifications
                await sendNotifications(
                    cabin: cabin,
                    newWeekends: newWeekendsDetected,
                    newSaturdays: newSaturdays,
                    totalNewDates: addedDates.count
                )

                // Create availability data
                let availability = CabinAvailability(
                    cabin: cabin,
                    availableDates: newDates,
                    weekends: newWeekends,
                    newDates: addedDates,
                    newWeekends: newWeekendsDetected
                )

                // Save to state and history
                await MainActor.run {
                    availabilityData[cabin.id] = availability
                    cabin.lastChecked = Date()
                    HistoryService.saveHistory(cabinId: cabin.cabinId, dates: newDates, context: modelContext)
                }

            } catch {
                print("Error fetching availability for \(cabin.name): \(error)")
            }
        }

        // Schedule background refresh after completing checks
        BackgroundTaskManager.shared.scheduleBackgroundRefresh()
    }

    private func findNewWeekends(in dates: [Date], analyzer: AvailabilityAnalyzer) -> [Weekend] {
        return analyzer.findAvailableWeekends(in: dates)
    }

    private func findNewSaturdays(in dates: [Date], existingWeekends: [Weekend]) -> [Date] {
        let calendar = Calendar.current
        let weekendSaturdays = Set(existingWeekends.map { $0.saturday })

        return dates.filter { date in
            let weekday = calendar.component(.weekday, from: date)
            let isSaturday = (weekday == 7) // Saturday
            let isAlreadyInWeekend = weekendSaturdays.contains(calendar.startOfDay(for: date))
            return isSaturday && !isAlreadyInWeekend
        }
    }

    private func sendNotifications(cabin: Cabin, newWeekends: [Weekend], newSaturdays: [Date], totalNewDates: Int) async {
        guard totalNewDates > 0 else { return }

        let notificationManager = NotificationManager.shared

        if !newWeekends.isEmpty {
            // NEW FULL WEEKENDS
            let weekendDates = newWeekends.map { formatWeekend($0) }.joined(separator: ", ")
            notificationManager.sendNotification(
                title: "\(cabin.name) - 🆕 NEW FULL WEEKENDS!",
                body: "Available: \(weekendDates)"
            )
        } else if !newSaturdays.isEmpty {
            // NEW SATURDAYS (but not full weekends)
            let saturdayDates = newSaturdays.map { formatDate($0) }.joined(separator: ", ")
            notificationManager.sendNotification(
                title: "\(cabin.name) - 🆕 NEW SATURDAYS!",
                body: "Available Saturdays: \(saturdayDates)"
            )
        } else if totalNewDates > 0 {
            // NEW DATES (but not weekends or Saturdays)
            notificationManager.sendNotification(
                title: "\(cabin.name) - New Availability",
                body: "\(totalNewDates) new date\(totalNewDates == 1 ? "" : "s") available"
            )
        }
    }

    private func formatWeekend(_ weekend: Weekend) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: weekend.friday)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

struct CabinRow: View {
    let cabin: Cabin
    let availability: CabinAvailability?

    var body: some View {
        HStack(spacing: 12) {
            // Cabin image
            AsyncImage(url: cabin.imageURL.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(.blue)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(cabin.name)
                    .font(.headline)

                if let availability = availability {
                    HStack(spacing: 12) {
                        // NEW weekends badge
                        if !availability.newWeekends.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("NEW")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green)
                            .clipShape(Capsule())
                            .fixedSize()
                        }

                        // Weekend count
                        if !availability.weekends.isEmpty {
                            Label("\(availability.weekends.count)", systemImage: "calendar.badge.checkmark")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }

                        // Total dates
                        Label("\(availability.availableDates.count)", systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let lastChecked = cabin.lastChecked {
                    Text("Last: \(lastChecked.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not checked yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let availability = availability, !availability.weekends.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
    }
}

#Preview {
    CabinListView()
        .modelContainer(for: Cabin.self, inMemory: true)
}
