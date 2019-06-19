// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct PathCommand: Command {
    func run(engine: XPkg) {
        let url: URL
        if engine.arguments.flag("self") {
            url = engine.xpkgCodeURL
        } else {
            let package = engine.existingPackage()
            let store = engine.arguments.flag("store")
            url = store ? package.store : package.local
        }
        engine.output.log(url.path)
    }
}
