// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DNTWatcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DNTWatcher",
            targets: ["DNTWatcher"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DNTWatcher",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/DNTWatcher"
        )
    ]
)
