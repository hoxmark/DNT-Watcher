import Foundation
import SwiftData

@Model
final class Cabin {
    var id: UUID
    var name: String
    var url: String
    var cabinDescription: String
    var isEnabled: Bool
    var imageURL: String?
    var lastChecked: Date?

    // Computed property for cabin ID
    var cabinId: String {
        let components = url.split(separator: "/").filter { !$0.isEmpty }
        guard let lastComponent = components.last else { return "" }
        return String(lastComponent)
    }

    init(id: UUID = UUID(),
         name: String,
         url: String,
         description: String,
         isEnabled: Bool = true,
         imageURL: String? = nil,
         lastChecked: Date? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.cabinDescription = description
        self.isEnabled = isEnabled
        self.imageURL = imageURL
        self.lastChecked = lastChecked
    }
}

// Helper struct for availability data (not persisted)
struct CabinAvailability: Identifiable {
    let id = UUID()
    let cabin: Cabin
    let availableDates: [Date]
    let weekends: [Weekend]
    let newDates: [Date]
    let newWeekends: [Weekend]
}
