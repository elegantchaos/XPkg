// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/07/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation
import Runner

struct InitCommand: Command {

    func run(engine: Engine) {
        engine.output.log("Initing")
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
        
        let user = engine.gitUserName() ?? ProcessInfo.processInfo.environment["USER"] ?? "Unknown"
        let manifest = manifestSource(for: name)
        let main = mainSource(for: name, user: user, date: Date())
        
        do {
            try writeFiles(manifest: manifest, main: main, to: root, engine: engine)
            engine.output.log("Inited package \(name).")
        } catch {
            engine.output.log("Failed to init package \(name).")
            engine.verbose.log(error)
        }
    }
    
    fileprivate func writeFiles(manifest: String, main: String, to root: URL, engine: Engine) throws {
        let runner = Runner(for: engine.gitURL)
        let fm = FileManager.default

        // create manifest
        try manifest.write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        
        // create source
        let source = root.appendingPathComponent(".xpkg")
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
    
    func manifestSource(for name: String) -> String {
        return """
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
    }
    
    func mainSource(for name: String, user: String, date: Date) -> String {
        let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        return """
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // \(name) - An XPgk package.
        // Created by \(user), \(formattedDate).
        // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

        import XPkgPackage

        let links: [InstalledPackage.ManifestLink] = []

        let package = InstalledPackage(fromCommandLine: CommandLine.arguments)
        try! package.performAction(fromCommandLine: CommandLine.arguments, links: links)
        """

    }
}
