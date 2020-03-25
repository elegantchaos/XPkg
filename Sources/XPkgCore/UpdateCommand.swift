// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 14/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Runner
import CommandShell

public struct UpdateCommand: ParsableCommand {
    @Flag(name: .customLong("self"), help: "Update xpkg itself.") var updateSelf: Bool
    @Argument(help: "The package to update.") var packageName: String?
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "update",
        abstract: "Update a package to the latest version."
    )

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        if updateSelf {
            updateSelf(engine: engine)
        } else if let packageName = packageName {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(from: packageName, manifest: manifest)
            update(package: package, engine: engine)
        } else {
            engine.output.log("Checking all packages for updates...")
            let _ = engine.forEachPackage { (package) in
                update(package: package, engine: engine)
            }
            engine.output.log("Done.")
        }
    }

    func update(package: Package, engine: Engine) {
        let state = package.needsUpdate(engine: engine)
        switch state {
            case .needsUpdate(let newerVersion):
                package.update(to: newerVersion, engine: engine)
            
            case .unchanged:
                engine.output.log("Package \(package.name) was unchanged.")
            
            case .notOnTag:
            engine.output.log("Package \(package.name) is modified locally or not at a published version.")
        
            default:
                engine.output.log("Could not fetch the latest version for \(package.name), so it has not been updated.")
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
