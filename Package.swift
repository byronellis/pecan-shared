// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "pecan-shared",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PecanShared", targets: ["PecanShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.23.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
    ],
    targets: [
        .target(
            name: "PecanShared",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Logging", package: "swift-log"),
            ],
            exclude: [
                "pecan.proto",
                "swift-protobuf-config.json",
                "grpc-swift-config.json",
            ]
        ),
        .testTarget(
            name: "PecanSharedTests",
            dependencies: [
                "PecanShared",
            ],
            path: "Tests/PecanSharedTests"
        ),
    ]
)
