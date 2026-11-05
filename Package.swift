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
    targets: [
        .target(
            name: "AppsOnAir-Core",
            path: "AppsOnAir-Core",
            resources: [
                .process("Resources/AppsOnAir-CoreInfo.plist")
            ]
        ),
        .target(
            name: "AppsOnAir-Core-ObjC",
            dependencies: ["AppsOnAir-Core"],
            path: "AppsOnAir_Core_ObjC",
            publicHeadersPath: "include"
        ),
    ]
)
