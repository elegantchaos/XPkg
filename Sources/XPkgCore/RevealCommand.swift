// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser

public struct RevealCommand: ParsableCommand {
    @Flag(help: "") var path: Bool
    @Argument(help: "") var packageName: String
    
    public init() {
    }
    
    public func run() throws {
        let manifest = engine.loadManifest()
        let package = engine.existingPackage(from: packageName, manifest: manifest)
        if path {
            engine.output.log(package.path)
        } else {
            package.reveal()
        }
    }
}
