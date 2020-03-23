// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 14/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Runner

public struct UpdateCommand: ParsableCommand {
    @Flag(name: .customLong("self"), help: "Update xpkg itself.") var updateSelf: Bool
    @Argument(help: "The package to update.") var packageName: String?
    
    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a package to the latest version."
    )

    public init() {
    }
    
    public func run() throws {
        if updateSelf {
            updateSelf(engine: engine)
        } else if let packageName = packageName {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(from: packageName, manifest: manifest)
            if let newerVersion = package.needsUpdate(engine: engine) {
                package.update(to: newerVersion, engine: engine)
                engine.output.log("Package \(package.name) was unchanged.")
            }
        } else {
            engine.output.log("Checking all packages for updates...")
            let _ = engine.forEachPackage { (package) in
                if let newerVersion = package.needsUpdate(engine: engine) {
                    package.update(to: newerVersion, engine: engine)
                } else {
                    engine.output.log("Package \(package.name) was unchanged.")
                }
            }
            engine.output.log("Done.")
        }
    }

    func updateSelf(engine: Engine) {
        engine.output.log("Updating xpkg.")
        let url = engine.xpkgURL
        let codeURL = url.appendingPathComponent("code")
        let runner = Runner(for: engine.gitURL, cwd: codeURL)
        if let result = try? runner.sync(arguments: ["pull"]) {
            engine.output.log(result.stdout)
        }

        let bootstrapURL = codeURL.appendingPathComponent(".bin").appendingPathComponent("bootstrap")
        let bootstrapRunner = Runner(for: bootstrapURL, cwd: codeURL)
        if let result = try? bootstrapRunner.sync() {
            engine.output.log(result.stdout)
        }
    }

}
