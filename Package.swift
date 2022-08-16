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
        .package(url: "https://github.com/elegantchaos/CommandShell.git", from: "2.1.5"),
        .package(url: "https://github.com/elegantchaos/Expressions.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/Files.git", from: "1.2.2"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.8.1"),
        .package(url: "https://github.com/elegantchaos/Runner.git", from: "1.3.2"),
        .package(url: "https://github.com/elegantchaos/SemanticVersion.git", from: "1.1.1"),
        .package(url: "https://github.com/elegantchaos/XPkgPackage.git", from: "1.2.0"),
        
        // tools
        .package(url: "https://github.com/elegantchaos/Versionator.git", from: "1.0.3"),
    ],
    
    targets: [
        .executableTarget(
            name: "XPkgCommand",
            
            dependencies: [
                "XPkgCore"
            ],
            plugins: [
                .plugin(name: "VersionatorPlugin", package: "Versionator")
            ]
        ),
        
            .target(
                name: "XPkgCore",
                
                dependencies: [
                    "CommandShell",
                    "Expressions",
                    "Files",
                    "Logger",
                    "Runner",
                    "SemanticVersion",
                    "XPkgPackage",
                ]
            ),
        
            .testTarget(
                name: "XPkgTests",
                dependencies: [
                    "XPkgCore"
                ]
            )
    ]
)

import Foundation
if ProcessInfo.processInfo.environment["RESOLVE_COMMAND_PLUGINS"] != nil {
    package.dependencies.append(contentsOf: [
        .package(url: "https://github.com/elegantchaos/ActionBuilderPlugin.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/SwiftFormatterPlugin.git", from: "1.0.2")
    ])
}
