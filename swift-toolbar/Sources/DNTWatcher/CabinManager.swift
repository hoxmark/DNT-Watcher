import Foundation

class CabinManager: ObservableObject {
    @Published var cabins: [CabinModel] = []

    private let userDefaultsKey = "savedCabins"
    private let configLoader = ConfigLoader()

    init() {
        loadCabins()
    }

    func loadCabins() {
        // Try loading from UserDefaults first
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedCabins = try? JSONDecoder().decode([CabinModel].self, from: savedData) {
            cabins = decodedCabins
            print("Loaded \(cabins.count) cabins from UserDefaults")

            // Fetch images for cabins that don't have them yet
            Task {
                await fetchMissingImages()
            }
            return
        }

        // Fall back to YAML file
        if let yamlCabins = configLoader.loadCabins() {
            cabins = yamlCabins.map { CabinModel(from: $0) }
            print("Loaded \(cabins.count) cabins from YAML")

            // Fetch images for all cabins
            Task {
                await fetchMissingImages()
            }

            // Save to UserDefaults for future use
            saveCabins()
        } else {
            cabins = []
            print("No cabins found")
        }
    }

    func saveCabins() {
        if let encoded = try? JSONEncoder().encode(cabins) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("Saved \(cabins.count) cabins to UserDefaults")
        }
    }

    func addCabin(_ cabin: CabinModel) {
        cabins.append(cabin)
        saveCabins()
    }

    func updateCabin(_ cabin: CabinModel) {
        if let index = cabins.firstIndex(where: { $0.id == cabin.id }) {
            cabins[index] = cabin
            saveCabins()
        }
    }

    func deleteCabin(_ cabin: CabinModel) {
        cabins.removeAll { $0.id == cabin.id }
        saveCabins()
    }

    func toggleCabin(_ cabin: CabinModel) {
        if let index = cabins.firstIndex(where: { $0.id == cabin.id }) {
            cabins[index].isEnabled.toggle()
            saveCabins()
        }
    }

    // Get enabled cabins in format expected by existing code
    func getEnabledCabins() -> [Cabin] {
        return cabins.filter { $0.isEnabled }.map { cabin in
            Cabin(
                name: cabin.name,
                cabinId: cabin.cabinId,
                description: cabin.description
            )
        }
    }

    // Export to YAML format (for backup)
    func exportToYAML() -> String {
        var yaml = "dnt_hytter:\n"
        for cabin in cabins {
            yaml += "  - navn: \"\(cabin.name)\"\n"
            yaml += "    url: \"\(cabin.url)\"\n"
            yaml += "    beskrivelse: \"\(cabin.description)\"\n\n"
        }
        return yaml
    }

    // Fetch images for cabins that don't have imageURL set
    @MainActor
    private func fetchMissingImages() async {
        for index in cabins.indices {
            if cabins[index].imageURL == nil {
                print("Fetching image for \(cabins[index].name)...")
                if let imageURL = await ImageFetcher.shared.fetchImageURL(for: cabins[index].url) {
                    cabins[index].imageURL = imageURL
                    print("Found image for \(cabins[index].name): \(imageURL)")
                }
            }
        }

        // Save updated cabins with images
        saveCabins()
    }

    // Fetch image for a specific cabin (used when adding new cabin)
    @MainActor
    func fetchImage(for cabin: CabinModel) async {
        guard let index = cabins.firstIndex(where: { $0.id == cabin.id }) else { return }

        if let imageURL = await ImageFetcher.shared.fetchImageURL(for: cabin.url) {
            cabins[index].imageURL = imageURL
            saveCabins()
        }
    }
}
