// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct ListCommand: Command {
    func run(engine: XPkg) {
        if engine.arguments.flag("compact") {
            listCompact(engine: engine)
        } else if engine.arguments.flag("verbose") {
            listVerbose(engine: engine)
        } else {
            listNormal(engine: engine)
        }
    }

    func listCompact(engine: XPkg) {
        let _ = engine.forEachPackage { (package) in
            engine.output.log("\(package.name)")
        }
    }

    func listNormal(engine: XPkg) {
        var gotLinked = false
        let gotPackages = engine.forEachPackage { (package) in
            let flags = package.linked ? "*" : " "
            gotLinked = gotLinked || package.linked
            engine.output.log("\(flags) \(package.name)")
        }


        if !gotPackages {
            engine.output.log("No packages installed.")
        } else if gotLinked {
            engine.output.log("\n(items marked with * are linked to external folders)")
        }
    }

    func listVerbose(engine: XPkg) {
        let gotPackages = engine.forEachPackage { (package) in
            let location = package.linked ? " (\(package.local.path))" : ""
            engine.output.log("\(package.name)\(location)")
        }

        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

}
