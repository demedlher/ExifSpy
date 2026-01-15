// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "dmdEXIFviewer",
    platforms: [
        .macOS(.v11) // Targeting macOS 11.0 or later
    ],
    products: [
        .executable(
            name: "dmdEXIFviewer",
            targets: ["dmdEXIFviewer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "dmdEXIFviewer",
            dependencies: [],
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        )
    ]
)