// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Logger
import Foundation

struct RemoveCommand: Command {
    let output = Logger.stdout

    func run(xpkg: XPkg) {
        let packageName = xpkg.arguments.argument("package")
        guard let package = Package(name: packageName, vault: xpkg.vaultURL) else {
            output.log("Package `\(packageName)` is not installed.")
            return
        }

        let runner = Runner(cwd: package.local)
        var safeToDelete = xpkg.arguments.option("force") as Bool
        if !safeToDelete {
            if let result = try? runner.sync(xpkg.gitURL, arguments: ["status", "--porcelain"]) {
                if (result.status != 0) || (result.stdout != "") {
                    output.log("Package `\(package)` is modified. Use --force to force deletion.")
                } else {
                    safeToDelete = true
                }
            }
        }

        if safeToDelete {
            do {
                try package.remove()
                output.log("Package \(package.name) removed.")
            } catch {
                output.log("Package \(package.name) could not be removed.\n\(error)")
            }
        }
    }
}
