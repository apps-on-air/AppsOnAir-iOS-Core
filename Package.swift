// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "AppsOnAir-Core",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "AppsOnAir-Core",
            targets: ["AppsOnAir-Core", "AppsOnAir-Core-ObjC"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", exact: "5.2.4")
    ],
    targets: [
        .target(
            name: "AppsOnAir-Core",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift")
            ],
            path: "AppsOnAir-Core",
            resources: [
                .process("Resources/AppCoreInfo.plist")
            ]
        ),
        .target(
            name: "AppsOnAir-Core-ObjC",
            dependencies: ["AppsOnAir-Core"],
            path: "AppsOnAir_Core_ObjC",
            publicHeadersPath: "include"
        )
    ]
) 
