// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FountainCoachSemanticScenographerKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FountainCoachSemanticScenographerKit", targets: ["FountainCoachSemanticScenographerKit"]),
        .executable(name: "fountain-score-midi-project", targets: ["ScoreMIDIProjectTool"])
    ],
    targets: [
        .target(name: "FountainCoachSemanticScenographerKit"),
        .executableTarget(name: "ScoreMIDIProjectTool", dependencies: ["FountainCoachSemanticScenographerKit"]),
        .testTarget(
            name: "FountainCoachSemanticScenographerKitTests",
            dependencies: ["FountainCoachSemanticScenographerKit"])
    ])
