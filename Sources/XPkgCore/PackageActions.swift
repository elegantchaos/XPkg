// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Runner
import XPkgAPI

extension Package {

    func run(action: String, engine: XPkg) throws {
        let configURL = local.appendingPathComponent(".xpkg.json")
        if fileManager.fileExists(atPath: configURL.path) {
            let installed = InstalledPackage(local: local, output: engine.output, verbose: engine.verbose)
            try installed.run(legacyAction: action, config: configURL)
        } else {
            let runner = Runner(for: engine.swiftURL, cwd: engine.vaultURL)
            if let result = try? runner.sync(arguments: ["run", "\(name)-xpkg-hooks", action]) {
                print(result.stdout)
                if result.status != 0 {
                    engine.output.log("Couldn't run action \(action).")
                }
            }
        }
    }
    


}
