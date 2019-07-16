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

        InstallCommand.install(engine: engine, packageSpec: name, linkTo: linkedURL)
//
//        let package = Package(remote: engine.remotePackageURL(name), vault: engine.vaultURL)
//        guard !package.installed else {
//            output.log("Package `\(name)` is already installed.")
//            return
//        }
//
//        let linkedURL = URL(fileURLWithPath: linkedPath).absoluteURL
//        package.link(to: linkedURL, removeable: false, useLocalName: true)
//        guard package.installed else {
//            output.log("Local path \(linkedURL) doesn't exist.")
//            return
//        }
//
//        engine.attempt(action:"Link") {
//            try package.save()
//            output.log("Linked \(linkedPath) as \(name).")
//        }
    }
}
