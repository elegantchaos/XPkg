// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Logger
import Foundation

struct LinkCommand: Command {
    let output = Logger.stdout

    func run(xpkg: XPkg) {
        let package = xpkg.arguments.argument("package")
        let local = xpkg.localPackageURL(package)
        let fm = FileManager.default

        guard !fm.fileExists(atPath: local.path) else {
            output.log("Package `\(package)` is already installed.")
            return
        }

        let linkedPath = xpkg.arguments.argument("path")
        guard fm.fileExists(atPath: linkedPath) else {
            output.log("Local path \(linkedPath) doesn't exist.")
            return
        }

        let linkedURL = URL(fileURLWithPath: linkedPath)
        try? fm.createSymbolicLink(at: local, withDestinationURL: linkedURL)
    }
}
