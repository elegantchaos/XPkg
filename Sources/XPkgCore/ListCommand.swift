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
        } else if engine.arguments.flag("full") {
            listFull(engine: engine)
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
            let linked = !package.local.absoluteString.contains(engine.vaultURL.absoluteString)
            let flags = linked ? "*" : " "
            gotLinked = gotLinked || linked
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

    func listFull(engine: Engine) {
        let gotPackages = engine.forEachPackage { (package) in
            let linked = !package.local.absoluteString.contains(engine.vaultURL.absoluteString)
//            let location = linked ? " --> \(package.local.path)" : ""
            let status = package.status(engine: engine)
            let version = package.currentVersion(engine: engine)
            let statusString = status == .pristine ? "" : " (\(status))"
            engine.output.log("\(package.name): \(version) \(package.url) \(statusString)\(package.path)")
        }

        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

}
