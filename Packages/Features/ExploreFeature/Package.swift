// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ExploreFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ExploreFeature", targets: ["ExploreFeature"])],
    dependencies: [
        .package(path: "../../DesignSystem"),
        .package(path: "../../PhotoAPI"),
        .package(path: "../PhotoViewerFeature"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", exact: "3.1.4"),
    ],
    targets: [
        .target(
            name: "ExploreFeature",
            dependencies: [
                "DesignSystem",
                "PhotoAPI",
                "PhotoViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ExploreFeatureTests",
            dependencies: [
                "ExploreFeature",
                "PhotoAPI",
                "PhotoViewerFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
