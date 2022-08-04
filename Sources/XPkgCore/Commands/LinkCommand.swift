// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation
import Runner

public struct LinkCommand: ParsableCommand {
    @Argument(help: "The name of the package to link to.") var packageName: String
    @Argument(help: "The path to the package.") var packagePath: String
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "link",
        abstract: "Link an existing folder as a package."
    )

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        let output = engine.output
        var package = self.packageName
        var path = self.packagePath

        if package == "" {
            package = engine.remoteNameForCwd()
        }
        
        if path == "" {
            path = engine.localRepoForCwd()
        }

        guard package != "", let linkedURL = URL(string: path) else {
            output.log("Couldn't infer package name/path.")
            return
        }

        let packageURL = linkedURL.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(at: packageURL) {
            try engine.install(packageSpec: package, linkTo: linkedURL)
        } else {
            engine.output.log("Linked \(package) as an alias.")
            let defaults = UserDefaults.standard
            var aliases: [String:String]
            if let current = defaults.dictionary(forKey: "aliases") as? [String:String] {
                aliases = current
            } else {
                aliases = [:]
            }
            
            let key = linkedURL.lastPathComponent
            aliases[key] = linkedURL.path
            defaults.set(aliases, forKey: "aliases")
        }
    }
}
