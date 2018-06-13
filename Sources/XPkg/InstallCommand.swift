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
        guard !package.registered else {
            output.log("Package `\(package.name)` is already installed.")
            return
        }

        let isProject = engine.arguments.option("project") as Bool
        if isProject {
            package.link(into: engine.projectsURL, removeable: true)
        }

        do {
            try package.clone(engine: engine)
            try package.save()
        } catch {
            print(error)
        }
    }
}
