// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation
import Runner

struct LinkCommand: Command {
    func run(engine: Engine) {
        let output = engine.output
        var name = engine.arguments.argument("package")
        var path = engine.arguments.argument("path")

        if name == "" {
            name = engine.remoteNameForCwd()
        }
        
        if path == "" {
            path = engine.localRepoForCwd()
        }

        guard name != "", let linkedURL = URL(string: path) else {
            output.log("Couldn't infer package name/path.")
            return
        }

        let packageURL = linkedURL.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(at: packageURL) {
            InstallCommand.install(engine: engine, packageSpec: name, linkTo: linkedURL)
        } else {
            engine.output.log("Linked \(name) as an alias.")
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
