// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FountainCoachSemanticScenographerKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FountainCoachSemanticScenographerKit", targets: ["FountainCoachSemanticScenographerKit"])
    ],
    targets: [
        .target(name: "FountainCoachSemanticScenographerKit"),
        .testTarget(
            name: "FountainCoachSemanticScenographerKitTests",
            dependencies: ["FountainCoachSemanticScenographerKit"])
    ])
