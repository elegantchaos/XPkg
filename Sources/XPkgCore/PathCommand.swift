// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct PathCommand: Command {
    func run(engine: Engine) {
        let url: URL
        if engine.arguments.flag("self") {
            url = engine.xpkgCodeURL
        } else if engine.arguments.flag("vault") {
            url = engine.vaultURL
        } else {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(manifest: manifest)
            url = package.local
        }
        engine.output.log(url.path)
    }
}
