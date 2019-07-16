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
        var linkedPath = engine.arguments.argument("path")

        let runner = Runner(for: engine.gitURL)
        if name == "" {
            // try to figure out the name from the current directory
            if let result = try? runner.sync(arguments: ["remote", "get-url", "origin"]) {
                if result.status == 0 {
                    name = result.stdout.trimmingCharacters(in: CharacterSet.newlines)
                }
            }
        }
        
        if linkedPath == "" {
            if let result2 = try? runner.sync(arguments: ["rev-parse", "--show-toplevel"]) {
                if result2.status == 0 {
                    linkedPath = result2.stdout.trimmingCharacters(in: CharacterSet.newlines)
                }
            }
        }

        guard name != "", let linkedURL = URL(string: linkedPath) else {
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
