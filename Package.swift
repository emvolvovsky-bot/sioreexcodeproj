// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Sioree",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Sioree",
            targets: ["Sioree"]),
    ],
    dependencies: [
        // Stripe dependencies removed - payments not implemented
    ],
    targets: [
        .target(
            name: "Sioree",
            dependencies: [
                // Stripe dependencies removed - payments not implemented
            ]),
        .testTarget(
            name: "SioreeTests",
            dependencies: ["Sioree"]),
    ]
)
