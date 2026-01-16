// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ExifSpy",
    platforms: [
        .macOS(.v11) // Targeting macOS 11.0 or later
    ],
    products: [
        .executable(
            name: "ExifSpy",
            targets: ["ExifSpy"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ExifSpy",
            dependencies: [],
            path: "Sources/ExifSpy",
            resources: [
                .process("Resources"),
                .process("Assets.xcassets")
            ]
        )
    ]
)