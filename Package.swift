// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XPkg",
    products: [
      .executable(name: "xpkg", targets: ["XPkgCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Logger", from: "1.0.8"),
        .package(url: "https://github.com/elegantchaos/Arguments", from: "1.0.0"),
        ],
    targets: [
      .target(
          name: "XPkgCommand",
          dependencies: ["XPkg"]),
        .target(
            name: "XPkg",
            dependencies: ["Arguments", "Logger"]),
        .testTarget(
            name: "XPkgTests",
            dependencies: ["XPkg"]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)