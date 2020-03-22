// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

public struct PathCommand: ParsableCommand {
    @Argument(help: "The package to show.") var packageName: String
    @Flag(name: .customLong("self"), help: "Perform the action on xpkg itself, rather than an installed package.") var asSelf: Bool
    @Flag(help: "Show the path to the vault.") var vault: Bool
    
    static public var configuration: CommandConfiguration = CommandConfiguration(
        name: "path"
        abstract: "Show the path of a package."
    )

    public init() {
    }
    
    public func run() throws {
        var url: URL? = nil
        
        if asSelf {
            url = engine.xpkgCodeURL
        } else if vault {
            url = engine.vaultURL
        } else {
            let name = packageName
            if let package = engine.possiblePackage(named: name, manifest: engine.loadManifest()) {
                url = package.local
            } else {
                let project = engine.projectsURL.appendingPathComponent(name)
                if FileManager.default.fileExists(at: project) {
                    url = project
                }
            }
        }
        
        if let found = url {
            engine.output.log(found.path)
        }
    }
}
