// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 11/07/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

public struct CheckCommand: ParsableCommand {
    static public var configuration: CommandConfiguration = CommandConfiguration(
        name: "check",
        abstract: "Check that an installed package is ok."
    )
    
    @Argument(help: "The package to check.") var packageName: String
    
    public init() {
    }
    
    public func run(engine: Engine) {
        if packageName == "" {
            let _ = engine.forEachPackage { (package) in
                check(package: package)
            }
        } else {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(from: packageName, manifest: manifest)
            check(package: package)
        }
    }
    
    func check(package: Package) {
        if package.check(engine: engine) {
            engine.output.log("\(package.name) ok.")
        } else {
            engine.output.log("\(package.name) missing.")
        }
    }
}
