// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Logger
import Foundation

struct InstallCommand: Command {
    let output = Logger.stdout

    func run(xpkg: XPkg) {
        let fm = FileManager.default
        let packageSpec = xpkg.arguments.argument("package")
        let package = Package(remote: xpkg.remotePackageURL(packageSpec), vault: xpkg.vaultURL)
        guard !package.registered else {
            output.log("Package `\(package.name)` is already installed.")
            return
        }

        let isProject = xpkg.arguments.option("project") as Bool
        if isProject {
            package.link(into: xpkg.projectsURL, removeable: true)
        }

        let container = package.local.deletingLastPathComponent()
        try? fm.createDirectory(at: container, withIntermediateDirectories: true)

        let runner = Runner(cwd: container)
        let gitArgs = ["clone", package.remote.absoluteString, package.local.path]
        if let result = try? runner.sync(xpkg.gitURL, arguments: gitArgs) {
            if result.status == 0 {
                output.log("Package `\(package)` installed.")
            } else {
                output.log("Failed to install `\(package)`.\n\n\(result.status) \(result.stdout) \(result.stderr)")
            }
        }

        do {
            try package.save()
        } catch {
            print(error)
        }
    }
}
