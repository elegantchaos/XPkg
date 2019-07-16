// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct ReinstallCommand: Command {
    func run(engine: Engine) {
        let manifest = engine.loadManifest()
        let package = engine.existingPackage(manifest: manifest)

        engine.attempt(action: "Reinstalling \(package.name).") {
            do {
                engine.verbose.log("Uninstalling \(package.name)")
                if try package.run(action: "remove", engine: engine) {
                    engine.output.log("Removed \(package.name).")
                }
                engine.verbose.log("Installing \(package.name)")
                if try package.run(action: "install", engine: engine) {
                    engine.output.log("Reinstalled \(package.name).")
                }
            } catch {
                engine.output.log("Reinstall of \(package.name) failed.")
                engine.verbose.log(error)
            }
        }
    }
}
