import Foundation
import SwiftData

@Model
final class AvailabilityHistory {
    var id: UUID
    var cabinId: String
    var checkedAt: Date
    var availableDates: [Date]

    init(id: UUID = UUID(), cabinId: String, checkedAt: Date = Date(), availableDates: [Date]) {
        self.id = id
        self.cabinId = cabinId
        self.checkedAt = checkedAt
        self.availableDates = availableDates
    }
}

// Helper for managing history
@MainActor
class HistoryService {
    static func getLatestHistory(for cabinId: String, context: ModelContext) -> AvailabilityHistory? {
        let descriptor = FetchDescriptor<AvailabilityHistory>(
            predicate: #Predicate { $0.cabinId == cabinId },
            sortBy: [SortDescriptor(\.checkedAt, order: .reverse)]
        )

        return try? context.fetch(descriptor).first
    }

    static func saveHistory(cabinId: String, dates: [Date], context: ModelContext) {
        let history = AvailabilityHistory(cabinId: cabinId, availableDates: dates)
        context.insert(history)

        // Keep only the last 30 history entries per cabin
        cleanupOldHistory(for: cabinId, context: context)
    }

    static func cleanupOldHistory(for cabinId: String, context: ModelContext, keepLast: Int = 30) {
        let descriptor = FetchDescriptor<AvailabilityHistory>(
            predicate: #Predicate { $0.cabinId == cabinId },
            sortBy: [SortDescriptor(\.checkedAt, order: .reverse)]
        )

        guard let allHistory = try? context.fetch(descriptor) else { return }

        // Delete entries beyond the keepLast limit
        if allHistory.count > keepLast {
            let toDelete = allHistory.suffix(from: keepLast)
            for entry in toDelete {
                context.delete(entry)
            }
        }
    }
}
