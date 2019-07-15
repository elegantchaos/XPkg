// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "XPkg",
    platforms: [
      .macOS(.v10_13)
    ],
    products: [
      .executable(name: "xpkg", targets: ["XPkgCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.3.7"),
        .package(url: "https://github.com/elegantchaos/Arguments.git", from: "1.0.4"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/BuilderConfiguration.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Builder.git", from: "1.1.1"),
        ],
    targets: [
      .target(
          name: "XPkgCommand",
          dependencies: ["XPkgCore"]),
        .target(
            name: "XPkgCore",
            dependencies: ["Arguments", "Logger", "Runner", "XPkgAPI"]),
        .target(
            name: "XPkgAPI",
            dependencies: ["Logger", "Runner"]),
        .target(
            name: "Configure",
          dependencies: ["BuilderConfiguration"]),
        .testTarget(
            name: "XPkgTests",
            dependencies: ["XPkgCore"]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)
