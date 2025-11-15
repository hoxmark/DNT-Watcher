import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Cabin.name) private var cabins: [Cabin]

    @State private var showingAddCabin = false

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
        }
    }

    private func deleteCabins(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cabins[index])
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
