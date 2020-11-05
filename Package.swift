// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ResourcesBridge",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "ResourcesBridge",
                 targets: ["ResourcesBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/eugenebokhan/Bonjour.git",
                 from: "2.1.0")
    ],
    targets: [
        .target(name: "ResourcesBridge",
                dependencies: ["Bonjour"])
    ]
)
