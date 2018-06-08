// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Logger
import Foundation

struct RemoveCommand: Command {
    func run(xpkg: XPkg) {
        let package = xpkg.arguments.argument("package")
        let local = xpkg.localPackageURL(package)
        let fm = FileManager.default

        guard fm.fileExists(atPath: local.path) else {
            Logger.stdout.log("Package `\(package)` is not installed.")
            return
        }

        let resolved = local.resolvingSymlinksInPath()
        let runner = Runner(cwd: resolved)
        if let result = try? runner.sync(xpkg.gitURL(), arguments: ["status"]) {
            print("\(result.status) \(result.stdout)")
        }
    }
}
