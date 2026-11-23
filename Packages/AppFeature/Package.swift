// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "AppFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AppFeature", targets: ["AppFeature"])],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Features/ExploreFeature"),
        .package(path: "../Features/PhotoViewerFeature"),
        .package(path: "../Features/SettingsFeature"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "DesignSystem",
                "ExploreFeature",
                "PhotoViewerFeature",
                "SettingsFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "AppFeatureTests", dependencies: ["AppFeature"]),
    ],
    swiftLanguageModes: [.v6]
)
