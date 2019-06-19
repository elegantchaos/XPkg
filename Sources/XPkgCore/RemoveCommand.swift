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
        let package = engine.existingPackage()

        var safeToDelete = engine.arguments.flag("force")

        // check the git status
        if package.installed {
            let runner = Runner(cwd: package.local)
            if !safeToDelete {
                if let result = try? runner.sync(engine.gitURL, arguments: ["status"]) {
                    engine.verbose.log(result.stdout)
                    if result.status != 0 {
                        output.log("Failed to check \(package.name) status - it might be modified or un-pushed. Use --force to force deletion.")
                    } else if !result.stdout.contains("nothing to commit, working tree clean") {
                        output.log("Package \(package.name) is modified. Use --force to force deletion.")
                    } else if result.stdout.contains("Your branch is ahead of") {
                        output.log("Package \(package.name) has un-pushed commits. Use --force to force deletion.")
                    } else if !result.stdout.contains("Your branch is up-to-date with") {
                        output.log("Package \(package.name) is not tracking remotely or may have un-pushed commits. Use --force to force deletion.")
                    } else {
                        // everything is committed and pushed, so we're ok
                        safeToDelete = true
                    }
                }
            }
        } else {
            // local directory seems to be missing - also safe to delete in that case
            safeToDelete = true
        }

        if safeToDelete {
            engine.attempt(action: "Remove \(package.name)") {
                try package.run(action:"remove", engine: engine)
                try package.remove()
                if package.linked && !package.removeable {
                    output.log("Package \(package.name) was linked to a local directory (\(package.local.path)). \nThe package has been uninstalled, but the linked directory was not touched.")
                } else {
                    output.log("Package \(package.name) removed.")
                }
            }
        }
    }
}