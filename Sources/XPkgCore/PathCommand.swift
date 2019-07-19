// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct PathCommand: Command {
    func run(engine: Engine) {
        var url: URL? = nil
        
        if engine.arguments.flag("self") {
            url = engine.xpkgCodeURL
        } else if engine.arguments.flag("vault") {
            url = engine.vaultURL
        } else {
            let name = engine.arguments.argument("package")
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
