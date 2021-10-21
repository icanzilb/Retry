// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "Retry",
    products: [
        .library(
            name: "Retry",
            targets: ["Retry"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Retry",
            path: "Retry/Classes"),
    ]
)
