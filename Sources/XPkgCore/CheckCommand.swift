// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 11/07/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation

public struct CheckCommand: ParsableCommand {
    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "check",
        abstract: "Check that an installed package is ok."
    )
    
    @Argument(help: "The package to check.") var packageName: String
    @OptionGroup() var common: CommandShellOptions

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        if packageName == "" {
            let _ = engine.forEachPackage { (package) in
                check(package: package, engine: engine)
            }
        } else {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(from: packageName, manifest: manifest)
            check(package: package, engine: engine)
        }
    }
    
    func check(package: Package, engine: Engine) {
        if package.check(engine: engine) {
            engine.output.log("\(package.name) ok.")
        } else {
            engine.output.log("\(package.name) missing.")
        }
    }
}
