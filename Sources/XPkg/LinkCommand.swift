// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct LinkCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let name = engine.arguments.argument("package")
        let package = Package(remote: engine.remotePackageURL(name), vault: engine.vaultURL)
        guard !package.installed else {
            output.log("Package `\(name)` is already installed.")
            return
        }

        let linkedPath = engine.arguments.argument("path")
        let linkedURL = URL(fileURLWithPath: linkedPath).absoluteURL
        package.link(to: linkedURL, removeable: false)
        guard package.installed else {
            output.log("Local path \(linkedURL) doesn't exist.")
            return
        }

        engine.attempt(action:"Link") {
            try package.save()
        }
    }
}
