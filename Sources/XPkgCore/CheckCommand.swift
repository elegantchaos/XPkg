// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 11/07/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct CheckCommand: Command {
    func run(engine: Engine) {
        let _ = engine.forEachPackage { (package) in
            if package.check(engine: engine) {
                engine.output.log("\(package.name) ok.")
            } else {
                engine.output.log("\(package.name) missing.")
            }
        }
    }
}
