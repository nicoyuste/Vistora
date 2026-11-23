// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "PhotoViewerFeature",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PhotoViewerFeature", targets: ["PhotoViewerFeature"])],
    dependencies: [
        .package(path: "../../DesignSystem"),
        .package(path: "../../PhotoAPI"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", exact: "3.1.4"),
    ],
    targets: [
        .target(
            name: "PhotoViewerFeature",
            dependencies: [
                "DesignSystem",
                "PhotoAPI",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
            ],
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
