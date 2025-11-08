import SwiftUI
import UserNotifications
import AppKit

struct SettingsView: View {
    @ObservedObject var cabinManager: CabinManager
    @State private var showingAddSheet = false
    @State private var editingCabin: CabinModel?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DNT Watcher Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Notification Settings Section
            notificationSection
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Cabin List
            if cabinManager.cabins.isEmpty {
                emptyState
            } else {
                cabinList
            }

            Divider()

            // Bottom toolbar
            HStack {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Cabin", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text("\(cabinManager.cabins.filter { $0.isEnabled }.count) active")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 560)
        .sheet(isPresented: $showingAddSheet) {
            AddEditCabinView(cabinManager: cabinManager, cabin: nil)
        }
        .sheet(item: $editingCabin) { cabin in
            AddEditCabinView(cabinManager: cabinManager, cabin: cabin)
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    private var notificationSection: some View {
        HStack(spacing: 12) {
            Image(systemName: notificationIcon)
                .foregroundColor(notificationColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications")
                    .font(.headline)
                Text(notificationStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if notificationStatus == .notDetermined {
                Button("Enable") {
                    requestNotificationPermission()
                }
                .buttonStyle(.borderedProminent)
            } else if notificationStatus == .denied {
                Button("Open Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)
            } else if notificationStatus == .authorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
    }

    private var notificationIcon: String {
        switch notificationStatus {
        case .authorized: return "bell.fill"
        case .denied: return "bell.slash.fill"
        default: return "bell"
        }
    }

    private var notificationColor: Color {
        switch notificationStatus {
        case .authorized: return .green
        case .denied: return .orange
        default: return .blue
        }
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "You'll be notified of new weekends and availability"
        case .denied: return "Notifications are disabled. Enable in System Settings."
        case .notDetermined: return "Enable notifications to get alerts for new availability"
        default: return "Checking notification status..."
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotificationPermission() {
        print("Requesting notification permissions...")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permissions: \(error)")
                    self.showAlert(
                        title: "Permission Error",
                        message: "Could not request notification permissions: \(error.localizedDescription)"
                    )
                    return
                }

                if granted {
                    print("Notifications enabled from Settings")
                    self.showAlert(
                        title: "Notifications Enabled! 🔔",
                        message: "You'll now receive alerts when new cabin availability appears."
                    )
                } else {
                    print("Notifications denied from Settings")
                    self.showAlert(
                        title: "Notifications Not Enabled",
                        message: "You can enable notifications later in System Settings → Notifications → DNTWatcher"
                    )
                }

                // Refresh status
                self.checkNotificationStatus()
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mountain.2")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Cabins Added")
                .font(.title2)
                .fontWeight(.medium)
            Text("Add cabins to monitor their availability")
                .foregroundColor(.secondary)
            Button(action: { showingAddSheet = true }) {
                Label("Add Your First Cabin", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cabinList: some View {
        List {
            ForEach(cabinManager.cabins) { cabin in
                CabinRow(cabin: cabin, cabinManager: cabinManager) {
                    editingCabin = cabin
                }
            }
            .onDelete(perform: deleteCabins)
        }
        .listStyle(.inset)
    }

    private func deleteCabins(at offsets: IndexSet) {
        for index in offsets {
            cabinManager.deleteCabin(cabinManager.cabins[index])
        }
    }
}

struct CabinRow: View {
    let cabin: CabinModel
    @ObservedObject var cabinManager: CabinManager
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Toggle("", isOn: Binding(
                get: { cabin.isEnabled },
                set: { _ in cabinManager.toggleCabin(cabin) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            // Cabin image thumbnail
            Group {
                if let imageURL = cabin.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "mountain.2.fill")
                                .foregroundColor(.secondary)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Placeholder while image is loading
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.secondary)
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Cabin info
            VStack(alignment: .leading, spacing: 4) {
                Text(cabin.name)
                    .font(.headline)
                    .foregroundColor(cabin.isEnabled ? .primary : .secondary)

                if !cabin.description.isEmpty {
                    Text(cabin.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text("ID: \(cabin.cabinId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospaced()
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Edit cabin")
        }
        .padding(.vertical, 4)
    }
}

struct AddEditCabinView: View {
    @ObservedObject var cabinManager: CabinManager
    let cabin: CabinModel?

    @State private var name: String
    @State private var url: String
    @State private var description: String
    @State private var isEnabled: Bool

    @Environment(\.dismiss) private var dismiss

    init(cabinManager: CabinManager, cabin: CabinModel?) {
        self.cabinManager = cabinManager
        self.cabin = cabin

        _name = State(initialValue: cabin?.name ?? "")
        _url = State(initialValue: cabin?.url ?? "https://hyttebestilling.dnt.no/hytte/")
        _description = State(initialValue: cabin?.description ?? "")
        _isEnabled = State(initialValue: cabin?.isEnabled ?? true)
    }

    var isValid: Bool {
        !name.isEmpty &&
        url.contains("hyttebestilling.dnt.no/hytte/") &&
        url.split(separator: "/").last != nil
    }

    var extractedID: String {
        url.split(separator: "/").last.map(String.init) ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(cabin == nil ? "Add New Cabin" : "Edit Cabin")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Form
            Form {
                Section {
                    TextField("Cabin Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Booking URL", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .help("Example: https://hyttebestilling.dnt.no/hytte/101297")

                    if !extractedID.isEmpty {
                        HStack {
                            Text("Cabin ID:")
                                .foregroundColor(.secondary)
                            Text(extractedID)
                                .monospaced()
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .font(.caption)
                    }

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)

                    Toggle("Monitor this cabin", isOn: $isEnabled)
                } header: {
                    Text("Cabin Details")
                        .font(.headline)
                }

                if !isValid && (!name.isEmpty || url != "https://hyttebestilling.dnt.no/hytte/") {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Invalid Input")
                                    .fontWeight(.medium)
                                if name.isEmpty {
                                    Text("• Name is required")
                                        .font(.caption)
                                }
                                if !url.contains("hyttebestilling.dnt.no/hytte/") {
                                    Text("• URL must be a valid DNT booking link")
                                        .font(.caption)
                                }
                            }
                            .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Bottom buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(cabin == nil ? "Add Cabin" : "Save Changes") {
                    saveCabin()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 500, height: 450)
    }

    private func saveCabin() {
        if let existingCabin = cabin {
            // Update existing cabin
            let updated = CabinModel(
                id: existingCabin.id,
                name: name,
                url: url,
                description: description,
                isEnabled: isEnabled,
                imageURL: existingCabin.imageURL  // Preserve existing image
            )
            cabinManager.updateCabin(updated)

            // If URL changed, fetch new image
            if url != existingCabin.url {
                Task {
                    await cabinManager.fetchImage(for: updated)
                }
            }
        } else {
            // Add new cabin
            let newCabin = CabinModel(
                name: name,
                url: url,
                description: description,
                isEnabled: isEnabled
            )
            cabinManager.addCabin(newCabin)

            // Fetch image for new cabin
            Task {
                await cabinManager.fetchImage(for: newCabin)
            }
        }
        dismiss()
    }
}

#Preview {
    SettingsView(cabinManager: CabinManager())
}
