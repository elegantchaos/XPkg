// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 02/08/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser

public struct RenameCommand: ParsableCommand {
    
    static public var configuration: CommandConfiguration = CommandConfiguration(
        name: "rename",
        abstract: "Rename a package."
    )

    public init() {
    }
    
    public func run(engine: Engine) {
//        let manifest = engine.loadManifest()
//        let package = engine.existingPackage(manifest: manifest)
//        let oldName = package.name
//        if package.installed {
//            engine.attempt(action: "Rename") {
//                let name = try engine.arguments.expectedArgument("name")
//                try package.rename(as: name, engine: engine)
//                engine.output.log("Renamed \(oldName) as \(name).")
//            }
//        }
    }
}
