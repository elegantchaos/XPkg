// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/07/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation
import Runner

public struct InitCommand: ParsableCommand {
    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a new package."
    )
    
    public init() {
    }
    
    public func run() throws {
        let fm = FileManager.default

        var name = engine.remoteNameForCwd()
        var path = engine.localRepoForCwd()
        if path.isEmpty {
            path = fm.currentDirectoryPath
        }
        let root = URL(fileURLWithPath: path)

        if name.isEmpty {
            name = root.lastPathComponent
        }
        
        do {
            try writeFiles(for: name, to: root, engine: engine)
            engine.output.log("Inited package \(name).")
        } catch {
            engine.output.log("Failed to init package \(name).")
            engine.verbose.log(error)
        }
    }
    
    fileprivate func writeFiles(for name: String, to root: URL, engine: Engine) throws {
        let user = engine.gitUserName() ?? ProcessInfo.processInfo.environment["USER"] ?? "Unknown"
        let now = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let manifest = manifestSource(for: name, user: user, date: now)
        let main = mainSource(for: name, user: user, date: now)
        let runner = Runner(for: engine.gitURL)
        let fm = FileManager.default

        // create manifest
        try manifest.write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        
        // create source
        let source = root.appendingPathComponent("Sources/\(name)-xpkg-hooks")
        try? fm.createDirectory(at: source, withIntermediateDirectories: true, attributes: nil)
        try main.write(to: source.appendingPathComponent("main.swift"), atomically: true, encoding: .utf8)
        
        // create gitignore if we've a global one to copy
        if let result = try? runner.sync(arguments: ["config", "--global", "core.excludesfile"]) {
            if result.status == 0 {
                let globalIgnoreURL = URL(fileURLWithPath: result.stdout.trimmingCharacters(in: .newlines))
                try? fm.copyItem(at: globalIgnoreURL, to: root.appendingPathComponent(".gitignore"))
            }
        }
        
        // git init if necessary
        if !fm.fileExists(at: root.appendingPathComponent(".git")) {
            let _ = try? runner.sync(arguments: ["init"])
        }
    }
    
    func manifestSource(for name: String, user: String, date: String) -> String {
        return """
// swift-tools-version:5.0

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// \(name) - An XPkg package.
// Created by \(user), \(date).
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

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
            dependencies: ["XPkgPackage"]),
    ]
)
"""
    }
    
    func mainSource(for name: String, user: String, date: String) -> String {
        return """
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// \(name) - An XPkg package.
// Created by \(user), \(date).
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XPkgPackage

let links: [InstalledPackage.ManifestLink] = []

let package = InstalledPackage(fromCommandLine: CommandLine.arguments)
try! package.performAction(fromCommandLine: CommandLine.arguments, links: links)
"""

    }
}
