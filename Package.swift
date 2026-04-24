// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftFlux",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SwiftFlux",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
