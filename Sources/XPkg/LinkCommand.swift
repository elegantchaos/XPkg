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
        let name = xpkg.arguments.argument("package")
        let package = Package(remote: xpkg.remotePackageURL(name), vault: xpkg.vaultURL)
        guard !package.installed else {
            output.log("Package `\(name)` is already installed.")
            return
        }

        let linkedPath = xpkg.arguments.argument("path")
        let linkedURL = URL(fileURLWithPath: linkedPath).absoluteURL
        package.link(to: linkedURL, removeable: false)
        guard package.installed else {
            output.log("Local path \(linkedURL) doesn't exist.")
            return
        }

        do {
            try package.save()
        } catch {
            print(error)
        }
    }
}
