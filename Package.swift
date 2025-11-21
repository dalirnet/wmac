// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WMac",
            targets: ["WMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WMac",
            path: "Sources"
        )
    ]
)
