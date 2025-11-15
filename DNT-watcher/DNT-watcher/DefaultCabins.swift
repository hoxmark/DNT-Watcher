import Foundation
import SwiftData

struct DefaultCabins {
    static let cabins: [(name: String, url: String, description: String)] = [
        (
            name: "Stallen",
            url: "https://hyttebestilling.dnt.no/hytte/101297",
            description: "Østmarka – idyllisk ved Røyrivann, kan bestilles som hel hytte. Passer for vennegjeng eller familiehelg."
        ),
        (
            name: "Skjennungsvolden",
            url: "https://hyttebestilling.dnt.no/hytte/101233402",
            description: "Nordmarka – klassisk storstue med utsikt over Skjennungen, lett adkomst fra Frognerseteren."
        ),
        (
            name: "Fuglemyrhytta",
            url: "https://hyttebestilling.dnt.no/hytte/101209",
            description: "Nordmarka – moderne DNT-hytte med fantastisk utsikt over Oslofjorden. Perfekt for en helg nær byen."
        )
    ]

    static func populateIfNeeded(modelContext: ModelContext) {
        // Check if database is empty
        let descriptor = FetchDescriptor<Cabin>()
        let existingCabins = (try? modelContext.fetch(descriptor)) ?? []

        guard existingCabins.isEmpty else {
            print("Cabins already exist, skipping default population")
            return
        }

        print("Populating default cabins...")

        // Add default cabins
        for cabinData in cabins {
            let cabin = Cabin(
                name: cabinData.name,
                url: cabinData.url,
                description: cabinData.description,
                isEnabled: true
            )
            modelContext.insert(cabin)

            // Fetch images in background
            Task {
                if let imageURL = await ImageFetcher.shared.fetchImageURL(for: cabinData.url) {
                    await MainActor.run {
                        cabin.imageURL = imageURL
                    }
                }
            }
        }

        // Save context
        do {
            try modelContext.save()
            print("Default cabins added successfully")
        } catch {
            print("Failed to save default cabins: \(error)")
        }
    }
}
