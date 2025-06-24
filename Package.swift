// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AppsOnAir-Core",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "AppsOnAir-Core",
            targets: ["AppsOnAir-Core"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.2.4")
    ],
    targets: [
        .target(
            name: "AppsOnAir-Core",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift")
            ],
            path: "AppsOnAir-Core"
        )
    ]
) 
