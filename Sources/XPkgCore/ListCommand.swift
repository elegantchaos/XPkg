// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct ListCommand: Command {
    func run(engine: Engine) {
        if engine.arguments.flag("oneline") {
          listOneline(engine: engine)
        } else if engine.arguments.flag("compact") {
            listCompact(engine: engine)
        } else if engine.arguments.flag("verbose") {
            listVerbose(engine: engine)
        } else {
            listNormal(engine: engine)
        }
    }

    func listOneline(engine: Engine) {
        var output: [String] = []
        let _ = engine.forEachPackage { (package) in
            output.append(package.name)
        }
        engine.output.log(output.joined(separator: " "))
    }

    func listCompact(engine: Engine) {
        let gotPackages = engine.forEachPackage { (package) in
            engine.output.log("\(package.name)")
        }
        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

    func listNormal(engine: Engine) {
        var gotLinked = false
        let gotPackages = engine.forEachPackage { (package) in
            let flags = package.linked ? "*" : " "
            gotLinked = gotLinked || package.linked
            let status = package.status(engine: engine)
            let statusString = status == .pristine ? "" : " (\(status))"
            engine.output.log("\(flags) \(package.name)\(statusString)")
        }


        if !gotPackages {
            engine.output.log("No packages installed.")
        } else if gotLinked {
            engine.output.log("\n(items marked with * are linked to external folders)")
        }
    }

    func listVerbose(engine: Engine) {
        let gotPackages = engine.forEachPackage { (package) in
            let location = package.linked ? " --> \(package.local.path)" : ""
            let status = package.status(engine: engine)
            let statusString = status == .pristine ? "" : " (\(status))"
            engine.output.log("\(package.name)\(statusString)\(location)")
        }

        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

}
