// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import Foundation

public struct PathCommand: ParsableCommand {
    @Argument(help: "") var package: String
    @Flag(name: .customLong("self"), help: "") var asSelf: Bool
    @Flag(help: "") var vault: Bool
    
    public init() {
    }
    
    public func run() throws {
        var url: URL? = nil
        
        if asSelf {
            url = engine.xpkgCodeURL
        } else if vault {
            url = engine.vaultURL
        } else {
            let name = package
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
