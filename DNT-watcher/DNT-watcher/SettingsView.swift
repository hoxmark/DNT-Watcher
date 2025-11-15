import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Cabin.name) private var cabins: [Cabin]

    @State private var showingAddCabin = false
    @State private var notificationsEnabled = true
    @State private var checkInterval: CheckInterval = .hourly
    @State private var showingClearHistoryAlert = false

    enum CheckInterval: String, CaseIterable, Identifiable {
        case hourly = "Every Hour"
        case twoHours = "Every 2 Hours"
        case fourHours = "Every 4 Hours"
        case sixHours = "Every 6 Hours"

        var id: String { rawValue }

        var seconds: TimeInterval {
            switch self {
            case .hourly: return 3600
            case .twoHours: return 7200
            case .fourHours: return 14400
            case .sixHours: return 21600
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Cabins") {
                    if cabins.isEmpty {
                        Text("No cabins added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(cabins) { cabin in
                            NavigationLink {
                                EditCabinView(cabin: cabin)
                            } label: {
                                CabinSettingsRow(cabin: cabin)
                            }
                        }
                        .onDelete(perform: deleteCabins)
                    }
                }

                Section {
                    Button {
                        showingAddCabin = true
                    } label: {
                        Label("Add Cabin", systemImage: "plus.circle.fill")
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Text("Receive alerts when new availability is found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Check Interval") {
                    Picker("Frequency", selection: $checkInterval) {
                        ForEach(CheckInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    Text("How often to check for availability in the background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showingClearHistoryAlert = true
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Platform", value: "iOS")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddCabin) {
                AddCabinView()
            }
            .alert("Clear History", isPresented: $showingClearHistoryAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("This will delete all availability history. You will see all availability as 'NEW' on the next check.")
            }
            .onAppear {
                loadSettings()
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
                if newValue {
                    Task {
                        _ = await NotificationManager.shared.requestPermission()
                    }
                }
            }
            .onChange(of: checkInterval) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: "checkInterval")
            }
        }
    }

    private func deleteCabins(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cabins[index])
        }
    }

    private func clearHistory() {
        let descriptor = FetchDescriptor<AvailabilityHistory>()
        if let allHistory = try? modelContext.fetch(descriptor) {
            for history in allHistory {
                modelContext.delete(history)
            }
            try? modelContext.save()
        }
    }

    private func loadSettings() {
        // Load notifications preference (default: true)
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true

        // Load check interval (default: hourly)
        if let intervalString = UserDefaults.standard.string(forKey: "checkInterval"),
           let interval = CheckInterval.allCases.first(where: { $0.rawValue == intervalString }) {
            checkInterval = interval
        }
    }
}

struct CabinSettingsRow: View {
    @Bindable var cabin: Cabin

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: cabin.imageURL.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(.blue)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(cabin.name)
                    .font(.headline)
                if !cabin.cabinDescription.isEmpty {
                    Text(cabin.cabinDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Toggle("", isOn: $cabin.isEnabled)
                .labelsHidden()
        }
    }
}

struct AddCabinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var url = ""
    @State private var description = ""
    @State private var isEnabled = true
    @State private var isFetchingImage = false

    var isValid: Bool {
        !name.isEmpty && !url.isEmpty && url.contains("hyttebestilling.dnt.no")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cabin Information") {
                    TextField("Name", text: $name)
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }

                if !url.isEmpty && !url.contains("hyttebestilling.dnt.no") {
                    Section {
                        Text("URL must be from hyttebestilling.dnt.no")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Cabin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCabin()
                    }
                    .disabled(!isValid || isFetchingImage)
                }
            }
        }
    }

    private func addCabin() {
        let cabin = Cabin(
            name: name,
            url: url,
            description: description,
            isEnabled: isEnabled
        )

        modelContext.insert(cabin)

        // Fetch image in background
        Task {
            isFetchingImage = true
            if let imageURL = await ImageFetcher.shared.fetchImageURL(for: url) {
                await MainActor.run {
                    cabin.imageURL = imageURL
                }
            }
            isFetchingImage = false
        }

        dismiss()
    }
}

struct EditCabinView: View {
    @Bindable var cabin: Cabin
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Cabin Information") {
                TextField("Name", text: $cabin.name)
                TextField("URL", text: $cabin.url)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Description", text: $cabin.cabinDescription, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Toggle("Enabled", isOn: $cabin.isEnabled)
            }

            Section {
                if let imageURL = cabin.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                }

                Button("Refresh Image") {
                    Task {
                        if let imageURL = await ImageFetcher.shared.fetchImageURL(for: cabin.url) {
                            await MainActor.run {
                                cabin.imageURL = imageURL
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Cabin")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Cabin.self, inMemory: true)
}
