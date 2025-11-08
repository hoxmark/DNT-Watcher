import Foundation
import Yams

struct Cabin {
    let name: String
    let cabinId: String
    let description: String
}

class ConfigLoader {
    func loadCabins() -> [Cabin]? {
        let fileManager = FileManager.default
        var configPath: String?

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
            // From Contents/MacOS, go up to the app bundle, then up to parent directory
            for _ in 0..<8 {
                searchPaths.append(bundlePath)
                bundlePath = (bundlePath as NSString).deletingLastPathComponent
            }
        }

        // 3. Bundle resource path
        if let bundleResourcePath = Bundle.main.resourcePath {
            searchPaths.append(bundleResourcePath)
        }

        // Search all paths
        for path in searchPaths {
            let candidatePath = (path as NSString).appendingPathComponent("dnt_hytter.yaml")
            if fileManager.fileExists(atPath: candidatePath) {
                configPath = candidatePath
                break
            }
        }

        guard let configPath = configPath else {
            print("Could not find dnt_hytter.yaml")
            print("Current directory: \(fileManager.currentDirectoryPath)")
            print("Searched paths: \(searchPaths.prefix(10))")
            return nil
        }

        print("Loading config from: \(configPath)")

        guard let yamlString = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            print("Failed to read config file")
            return nil
        }

        guard let yaml = try? Yams.load(yaml: yamlString) as? [String: Any],
              let cabinsData = yaml["dnt_hytter"] as? [[String: String]] else {
            print("Failed to parse YAML")
            return nil
        }

        var cabins: [Cabin] = []

        for cabinData in cabinsData {
            guard let name = cabinData["navn"],
                  let url = cabinData["url"] else {
                continue
            }

            let description = cabinData["beskrivelse"] ?? ""

            // Extract cabin ID from URL
            if let cabinId = extractCabinId(from: url) {
                cabins.append(Cabin(name: name, cabinId: cabinId, description: description))
            }
        }

        print("Loaded \(cabins.count) cabins")
        return cabins
    }

    private func extractCabinId(from url: String) -> String? {
        // Extract the last component after the last '/'
        let components = url.split(separator: "/")
        guard let lastComponent = components.last else { return nil }
        return String(lastComponent)
    }
}
