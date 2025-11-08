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

    func getAvailability(cabinId: String) -> AvailabilityResponse? {
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
            print("Failed to calculate end date")
            return nil
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
            print("Failed to construct URL")
            return nil
        }

        print("Fetching: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let semaphore = DispatchSemaphore(value: 0)
        var result: AvailabilityResponse?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoder = JSONDecoder()
                result = try decoder.decode(AvailabilityResponse.self, from: data)
            } catch {
                print("Failed to decode response: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString.prefix(500))")
                }
            }
        }

        task.resume()
        semaphore.wait()

        return result
    }
}
