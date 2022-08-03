// swift-tools-version:5.6

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
        .package(url: "https://github.com/elegantchaos/BuilderConfiguration.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Builder.git", from: "1.2.1"),
        .package(url: "https://github.com/elegantchaos/CommandShell", from: "2.1.3"),
        .package(url: "https://github.com/elegantchaos/Expressions.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/Files.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.5"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.3.0"),
        .package(url: "https://github.com/elegantchaos/XPkgPackage.git", from: "1.0.9")
        ],
    targets: [
      .executableTarget(
          name: "XPkgCommand",
          dependencies: ["XPkgCore"]),
        .target(
            name: "XPkgCore",
            dependencies: [
                "Expressions",
                "Files",
                "Logger",
                "Runner",
                "XPkgPackage",
                "CommandShell"
        ]),
        .executableTarget(
            name: "Configure",
          dependencies: ["BuilderConfiguration"]),
        .testTarget(
            name: "XPkgTests",
            dependencies: ["XPkgCore"]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)
