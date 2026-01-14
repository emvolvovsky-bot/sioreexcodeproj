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
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.0.0"),
    ],
    targets: [
        .target(
            name: "Sioree",
            dependencies: [
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "StripeCore", package: "stripe-ios"),
            ]),
        .testTarget(
            name: "SioreeTests",
            dependencies: ["Sioree"]),
    ]
)
