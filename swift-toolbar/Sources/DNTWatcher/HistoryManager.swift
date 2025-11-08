import Foundation

class HistoryManager {
    private let fileManager = FileManager.default
    private let isoDateFormatter = ISO8601DateFormatter()

    private func getHistoryDirectory() -> String? {
        // Try multiple search strategies
        var searchPaths: [String] = []

        // 1. Current working directory and parents
        var currentPath = fileManager.currentDirectoryPath
        for _ in 0..<5 {
            searchPaths.append(currentPath)
            currentPath = (currentPath as NSString).deletingLastPathComponent
        }

        // 2. Executable's directory and parents (for .app bundles)
        if let executablePath = Bundle.main.executablePath {
            var bundlePath = (executablePath as NSString).deletingLastPathComponent
            for _ in 0..<8 {
                searchPaths.append(bundlePath)
                bundlePath = (bundlePath as NSString).deletingLastPathComponent
            }
        }

        // Search for existing history directory
        for path in searchPaths {
            let candidatePath = (path as NSString).appendingPathComponent("history")
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: candidatePath, isDirectory: &isDirectory), isDirectory.boolValue {
                print("Found history directory: \(candidatePath)")
                return candidatePath
            }
        }

        // If not found, try to create it next to the config file
        for path in searchPaths {
            let configPath = (path as NSString).appendingPathComponent("dnt_hytter.yaml")
            if fileManager.fileExists(atPath: configPath) {
                let historyPath = (path as NSString).appendingPathComponent("history")
                do {
                    try fileManager.createDirectory(atPath: historyPath, withIntermediateDirectories: true)
                    print("Created history directory: \(historyPath)")
                    return historyPath
                } catch {
                    print("Failed to create history directory: \(error)")
                }
            }
        }

        print("Could not find or create history directory")
        print("Searched paths: \(searchPaths.prefix(10))")
        return nil
    }

    func saveHistory(dates: [Date], for cabinId: String) {
        guard let historyDir = getHistoryDirectory() else {
            print("Could not find or create history directory")
            return
        }

        // Create filename: HH-DD-MM-YYYY-{cabinId}.json
        let formatter = DateFormatter()
        formatter.dateFormat = "HH-dd-MM-yyyy"
        let timestamp = formatter.string(from: Date())
        let filename = "\(timestamp)-\(cabinId).json"
        let filepath = (historyDir as NSString).appendingPathComponent(filename)

        // Convert dates to ISO strings
        let dateStrings = dates.map { isoDateFormatter.string(from: $0) }

        do {
            let jsonData = try JSONEncoder().encode(dateStrings)
            try jsonData.write(to: URL(fileURLWithPath: filepath))
            print("Saved history: \(filename)")
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    func loadLatestHistory(for cabinId: String) -> [Date] {
        guard let historyDir = getHistoryDirectory() else {
            print("Could not find history directory")
            return []
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: historyDir)
            let cabinFiles = files.filter { $0.hasSuffix("-\(cabinId).json") }
                .sorted()
                .reversed()

            guard let latestFile = cabinFiles.first else {
                print("No history found for cabin \(cabinId)")
                return []
            }

            let filepath = (historyDir as NSString).appendingPathComponent(latestFile)
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: filepath))
            let dateStrings = try JSONDecoder().decode([String].self, from: jsonData)

            let dates = dateStrings.compactMap { isoDateFormatter.date(from: $0) }
            print("Loaded \(dates.count) dates from \(latestFile)")
            return dates

        } catch {
            print("Failed to load history: \(error)")
            return []
        }
    }
}
