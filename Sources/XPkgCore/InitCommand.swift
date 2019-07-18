// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/07/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct InitCommand: Command {
    func run(engine: Engine) {
        engine.output.log("Initing")
        var name = engine.remoteNameForCwd()
        var path = engine.localRepoForCwd()
        if path.isEmpty {
            path = FileManager.default.currentDirectoryPath
        }
        let root = URL(fileURLWithPath: path)

        if name.isEmpty {
            name = root.lastPathComponent
        }
        
        let package = """
// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "\(name)",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "\(name)-xpkg-hooks", targets: ["\(name)-xpkg-hooks"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/XPkgPackage", from:"1.0.0"),
    ],
    targets: [
        .target(
            name: "\(name)-xpkg-hooks",
            dependencies: ["XPkgPackage"]
            path: ".xpkg"),
    ]
)
"""
    
        let user = ProcessInfo.processInfo.environment["USER"] ?? "Unknown"
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
    let main = """
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// \(name) - An XPgk package.
// Created by \(user), \(date).
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XPkgPackage

let links: [InstalledPackage.ManifestLink] = []

let package = InstalledPackage(fromCommandLine: CommandLine.arguments)
try! package.performAction(fromCommandLine: CommandLine.arguments, links: links)
"""
        
        do {
            try package.write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
            let source = root.appendingPathComponent(".xpkg")
            try? FileManager.default.createDirectory(at: source, withIntermediateDirectories: true, attributes: nil)
            try main.write(to: source.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)
            engine.output.log("Inited package \(name).")
        } catch {
            engine.output.log("Failed to init package \(name).")
            engine.verbose.log(error)
        }
    }
    
}
