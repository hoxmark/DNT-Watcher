import Foundation

extension DateFormatter {
    /// Norwegian date formatter for short dates (e.g., "5 des")
    static let norwegianShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO") // Norwegian Bokmål
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    /// Norwegian date formatter for medium dates (e.g., "5. desember")
    static let norwegianMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateFormat = "d. MMMM"
        return formatter
    }()

    /// Norwegian date formatter with year (e.g., "5. des 2025")
    static let norwegianWithYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateFormat = "d. MMM yyyy"
        return formatter
    }()

    /// Norwegian date formatter for full date (e.g., "5. desember 2025")
    static let norwegianFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter
    }()
}

extension Date {
    /// Format date as short Norwegian format (e.g., "5 des")
    var norwegianShort: String {
        DateFormatter.norwegianShort.string(from: self)
    }

    /// Format date as medium Norwegian format (e.g., "5. desember")
    var norwegianMedium: String {
        DateFormatter.norwegianMedium.string(from: self)
    }

    /// Format date with year (e.g., "5. des 2025")
    var norwegianWithYear: String {
        DateFormatter.norwegianWithYear.string(from: self)
    }

    /// Format date as full Norwegian format (e.g., "5. desember 2025")
    var norwegianFull: String {
        DateFormatter.norwegianFull.string(from: self)
    }
}
