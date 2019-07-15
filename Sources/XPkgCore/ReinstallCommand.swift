// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct ReinstallCommand: Command {
    func run(engine: XPkg) {
        let manifest = engine.loadManifest()
        let package = engine.existingPackage(manifest: manifest)

        engine.attempt(action: "Reinstall") {
            try package.run(action: "remove", engine: engine)
            try package.run(action: "install", engine: engine)
        }
    }
}
