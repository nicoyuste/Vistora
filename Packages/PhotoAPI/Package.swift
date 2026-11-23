// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "PhotoAPI",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "PhotoAPI", targets: ["PhotoAPI"])],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
    ],
    targets: [
        .target(
            name: "PhotoAPI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(name: "PhotoAPITests", dependencies: ["PhotoAPI"]),
    ],
    swiftLanguageModes: [.v6]
)
