// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct ListCommand: Command {
    func run(engine: XPkg) {
        let fm = FileManager.default
        let vault = engine.vaultURL
        let gotPackages = engine.forEachPackage { (package) in
            let location = package.linked ? " (\(package.local.path))" : ""
            print("\(package.name)\(location)")
        }

        if !gotPackages {
            print("No packages installed.")
        }
    }
}
