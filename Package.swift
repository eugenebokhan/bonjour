// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Bonjour",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "Bonjour",
                 targets: ["Bonjour"]),
    ],
    targets: [
        .target(name: "Bonjour",
                linkerSettings: [
                    .linkedFramework("MultipeerConnectivity"),
                    .linkedFramework("CommonCrypto")
                ])
    ]
)
