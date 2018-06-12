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
        let package = xpkg.arguments.argument("package")
        let local = xpkg.localPackageURL(package)
        let fm = FileManager.default

        if fm.fileExists(atPath: local.path) {
            output.log("Package `\(package)` is already installed.")
        } else {
            let remote = xpkg.remotePackageURL(package)
            let isProject = xpkg.arguments.option("project") as Bool
            let container : URL
            if isProject {
                container = xpkg.projectsURL
            } else {
                container = local.deletingLastPathComponent()
            }
            try? fm.createDirectory(at: container, withIntermediateDirectories: true)

            let runner = Runner(cwd: container)
            let gitArgs = ["clone", remote.absoluteString]
            if let result = try? runner.sync(xpkg.gitURL, arguments: gitArgs) {
                if result.status == 0 {
                    output.log("Package `\(package)` installed.")
                } else {
                    output.log("Failed to install `\(package)`.\n\n\(result.status) \(result.stdout) \(result.stderr)")
                }
            }
        }
    }
}
