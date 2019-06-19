// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(url: "https://github.com/elegantchaos/Builder.git", from: "1.0.9"),
        .package(url: "https://github.com/elegantchaos/BuilderConfiguration.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Logger", from: "1.0.8"),
        .package(url: "https://github.com/elegantchaos/Arguments", from: "1.0.2"),
        ],
    targets: [
      .target(
          name: "XPkgCommand",
          dependencies: ["XPkg"]),
        .target(
            name: "XPkg",
            dependencies: ["Arguments", "Logger"]),
        .target(
            name: "Configure",
          dependencies: ["BuilderConfiguration"]),
        .testTarget(
            name: "XPkgTests",
            dependencies: ["XPkg", "XPkgCommand"]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)
