// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct InstallCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let packageSpec = engine.arguments.argument("package")
        let package = Package(remote: engine.remotePackageURL(packageSpec), vault: engine.vaultURL)
        let rerun = engine.arguments.option("rerun") as Bool

        guard !package.registered || rerun else {
            output.log("Package `\(package.name)` is already installed.")
            return
        }

        let isProject = engine.arguments.option("project") as Bool
        if isProject {
            package.link(into: engine.projectsURL, removeable: true)
        }

        engine.attempt(action: "Install") {
            if !rerun {
                try package.clone(engine: engine)
                if let name = engine.arguments.option("as") {
                    try package.rename(as: name, engine: engine)
                }
                try package.save()
            }
            try package.run(action: "install", engine: engine)
        }
    }
}
