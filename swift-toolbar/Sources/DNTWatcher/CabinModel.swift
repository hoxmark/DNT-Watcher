import Foundation

struct CabinModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var description: String
    var isEnabled: Bool
    var imageURL: String?

    var cabinId: String {
        // Extract cabin ID from URL
        let components = url.split(separator: "/").filter { !$0.isEmpty }
        guard let lastComponent = components.last else { return "" }
        return String(lastComponent)
    }

    init(id: UUID = UUID(), name: String, url: String, description: String, isEnabled: Bool = true, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.description = description
        self.isEnabled = isEnabled
        self.imageURL = imageURL
    }

    // Convert from ConfigLoader.Cabin
    init(from cabin: Cabin) {
        self.id = UUID()
        self.name = cabin.name
        self.url = "https://hyttebestilling.dnt.no/hytte/\(cabin.cabinId)"
        self.description = cabin.description
        self.isEnabled = true
        self.imageURL = nil  // Will be fetched later
    }
}
