// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser

public struct RevealCommand: ParsableCommand {
    @Argument(help: "The package to reveal.") var packageName: String
    @Flag(help: "Print the package path.") var path: Bool

    static public var configuration: CommandConfiguration = CommandConfiguration(
        name: "reveal",
        abstract: "Reveal a package in the finder."
    )

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
