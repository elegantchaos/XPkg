// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct RevealCommand: Command {
    func run(engine: Engine) {
        let manifest = engine.loadManifest()
        let package = engine.existingPackage(manifest: manifest)
        if engine.arguments.flag("path") {
            engine.output.log(package.path)
        } else {
            package.reveal()
        }
    }
}
