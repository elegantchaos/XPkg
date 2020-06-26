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
        .package(url: "https://github.com/elegantchaos/XPkgPackage.git", from: "1.0.8"),
        .package(url: "https://github.com/elegantchaos/Files.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.3"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.3.0"),
        .package(url: "https://github.com/elegantchaos/BuilderConfiguration.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Builder.git", from: "1.2.0"),
        .package(url: "https://github.com/elegantchaos/CommandShell", from: "2.1.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.4"),
        ],
    targets: [
      .target(
          name: "XPkgCommand",
          dependencies: ["XPkgCore"]),
        .target(
            name: "XPkgCore",
            dependencies: [
                "Files",
                "Logger",
                "Runner",
                "XPkgPackage",
                "CommandShell",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]),
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
