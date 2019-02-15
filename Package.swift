// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "NIORabbitMQ",
    products: [
        .library(
            name: "NIORabbitMQ",
            targets: ["NIORabbitMQ"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.13.0")
    ],
    targets: [
        .target(
            name: "NIORabbitMQ", dependencies: ["NIO"]),
        .testTarget(
            name: "NIORabbitMQTests", dependencies: ["NIORabbitMQ"]),
    ]
)
