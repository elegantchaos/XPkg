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
        let package = xpkg.arguments.argument("package")
        let local = xpkg.localPackageURL(package)
        let fm = FileManager.default

        guard fm.fileExists(atPath: local.path) else {
            output.log("Package `\(package)` is not installed.")
            return
        }

        let resolved = local.resolvingSymlinksInPath()
        let runner = Runner(cwd: resolved)
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
            try? fm.removeItem(at: local)
        }
    }
}
