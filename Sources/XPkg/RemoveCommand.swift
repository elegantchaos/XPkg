// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct RemoveCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let packageName = engine.arguments.argument("package")
        guard let package = Package(name: packageName, vault: engine.vaultURL) else {
            output.log("Package `\(packageName)` is not installed.")
            return
        }

        let runner = Runner(cwd: package.local)
        var safeToDelete = engine.arguments.option("force") as Bool
        if !safeToDelete {
            if let result = try? runner.sync(engine.gitURL, arguments: ["status", "--porcelain"]) {
                if (result.status != 0) || (result.stdout != "") {
                    output.log("Package `\(package)` is modified. Use --force to force deletion.")
                } else {
                    safeToDelete = true
                }
            }
        }

        if safeToDelete {
            do {
                try package.run(command:"remove", engine: engine)
                try package.remove()
                if package.linked && !package.removeable {
                    output.log("Package \(package.name) was linked to a local directory (\(package.local.path)). \nThe package has been uninstalled, but the linked directory was not touched.")
                } else {
                    output.log("Package \(package.name) removed.")
                }
            } catch {
                output.log("Package \(package.name) could not be removed.\n\(error)")
            }
        }
    }
}
