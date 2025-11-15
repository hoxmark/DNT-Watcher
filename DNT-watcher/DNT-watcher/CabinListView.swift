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
                let response = try await apiClient.getAvailability(cabinId: cabin.cabinId)
                let dates = analyzer.extractAvailableDates(from: response)
                let weekends = analyzer.findAvailableWeekends(in: dates)

                // For now, we'll show all as new (later we'll implement history tracking)
                let availability = CabinAvailability(
                    cabin: cabin,
                    availableDates: dates,
                    weekends: weekends,
                    newDates: [],
                    newWeekends: []
                )

                await MainActor.run {
                    availabilityData[cabin.id] = availability
                    cabin.lastChecked = Date()
                }

            } catch {
                print("Error fetching availability for \(cabin.name): \(error)")
            }
        }
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
                    HStack(spacing: 16) {
                        if !availability.weekends.isEmpty {
                            Label("\(availability.weekends.count)", systemImage: "calendar.badge.checkmark")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
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
