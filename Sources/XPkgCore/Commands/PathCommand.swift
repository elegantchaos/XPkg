// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation

public struct PathCommand: ParsableCommand {
    @Argument(help: "The package to show.") var packageName: String?
    @Flag(name: .customLong("self"), help: "Perform the action on xpkg itself, rather than an installed package.") var asSelf = false
    @Flag(help: "Show the path to the vault.") var vault = false
    @Flag(help: "Show the path to the projects folder.") var projects = false
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "path",
        abstract: "Show the path of a package."
    )

    public init() {
    }

    public func run() throws {
        let engine: Engine = common.loadEngine()
        var url: URL? = nil

        if asSelf {
            url = engine.xpkgCodeURL
        } else if vault {
            url = engine.vaultURL
        } else if projects {
            url = engine.projectsURL
        } else if let name = packageName {
            if let package = engine.possiblePackage(named: name, manifest: try engine.loadManifest()) {
                url = package.local
            } else {
                let project = engine.projectsURL.appendingPathComponent(name)
                if FileManager.default.fileExists(at: project) {
                    url = project
                }
                let website = engine.websitesURL.appendingPathComponent(name)
                if FileManager.default.fileExists(at: website) {
                    url = website
                }
            }
        } else {
            throw ValidationError("Package name required.")
        }

        if let found = url {
            engine.output.log(found.path)
        }
    }
}
