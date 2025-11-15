import Foundation

class ImageFetcher {
    static let shared = ImageFetcher()

    private init() {}

    /// Fetches the first image URL from a DNT cabin booking page
    func fetchImageURL(for cabinURL: String) async -> String? {
        guard let url = URL(string: cabinURL) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let html = String(data: data, encoding: .utf8) else {
                return nil
            }

            // Extract first Cloudinary image URL with alt="mainImage"
            return extractFirstImageURL(from: html)

        } catch {
            print("Error fetching cabin page: \(error)")
            return nil
        }
    }

    private func extractFirstImageURL(from html: String) -> String? {
        // Pattern: src="https://res.cloudinary.com/ntb/image/upload/..."
        let pattern = #"src="(https://res\.cloudinary\.com/ntb/image/upload/[^"]+)""#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

        if let match = results.first {
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }

        return nil
    }
}
