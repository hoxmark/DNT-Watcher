import Foundation

class DNTAPIClient {
    private let baseURL = "https://hyttebestilling.dnt.no/api/booking/availability-calendar"

    struct AvailabilityResponse: Codable {
        let data: AvailabilityData
    }

    struct AvailabilityData: Codable {
        let availabilityList: [AvailabilityItem]
    }

    struct AvailabilityItem: Codable {
        let date: String
        let products: [Product]
    }

    struct Product: Codable {
        let available: Int
    }

    func getAvailability(cabinId: String) async throws -> AvailabilityResponse {
        let calendar = Calendar.current
        let today = Date()
        let fromDate = today

        // Calculate "November 1st of next year"
        let currentYear = calendar.component(.year, from: today)
        let nextYear = currentYear + 1
        var components = DateComponents()
        components.year = nextYear
        components.month = 11
        components.day = 1

        guard let toDate = calendar.date(from: components) else {
            throw APIError.invalidDate
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let fromDateString = dateFormatter.string(from: fromDate)
        let toDateString = dateFormatter.string(from: toDate)

        var components_url = URLComponents(string: baseURL)!
        components_url.queryItems = [
            URLQueryItem(name: "cabinId", value: cabinId),
            URLQueryItem(name: "fromDate", value: fromDateString),
            URLQueryItem(name: "toDate", value: toDateString)
        ]

        guard let url = components_url.url else {
            throw APIError.invalidURL
        }

        print("Fetching: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AvailabilityResponse.self, from: data)
    }

    enum APIError: Error {
        case invalidURL
        case invalidDate
        case invalidResponse
    }
}
