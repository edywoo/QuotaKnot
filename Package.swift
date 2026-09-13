// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "QuotaKnot",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "QuotaKnot", targets: ["QuotaKnot"])
    ],
    targets: [
        .target(name: "QuotaKnotCore"),
        .executableTarget(
            name: "QuotaKnot",
            dependencies: ["QuotaKnotCore"]
        ),
        .executableTarget(
            name: "QuotaKnotCoreChecks",
            dependencies: ["QuotaKnotCore"]
        )
    ]
)
