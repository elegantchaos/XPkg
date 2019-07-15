// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct InstallCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let packageSpec = engine.arguments.argument("package")

        let manifest = engine.loadManifest()
        
        // do a quick check first for an existing local package with the name/spec
        if let package = manifest.package(named: packageSpec) {
            output.log("Package `\(package.name)` is already installed.")
            return
        }

        output.log("Searching for package \(packageSpec)...")
        let url = engine.remotePackageURL(packageSpec)
        var updatedManifest = manifest
        
        let package = Package(url: url, version: "1.0.0")
        updatedManifest = manifest
        updatedManifest.add(package: package)
        
        guard let resolved = engine.updateManifest(from: manifest, to: updatedManifest), resolved.dependencies.count > manifest.dependencies.count else {
            output.log("Couldn't add `\(packageSpec)`.")
            return
        }
        
        if let package = resolved.package(withURL: url) {
            let cleanup = {
                engine.saveManifest(manifest: manifest)
            }
            
            engine.attempt(action: "Install", cleanup: cleanup) {
                //            if !rerun {
                //                try package.clone(engine: engine)
                //                if let name = engine.arguments.option("as") {
                //                    try package.rename(as: name, engine: engine)
                //                }
                //                try package.save()
                //            }
                try package.run(action: "install", engine: engine)
            }

        }
//        let package = Package(remote: , vault: engine.vaultURL)
//        let rerun = engine.arguments.flag("rerun")
//
//        guard !package.registered || rerun else {
//            output.log("Package `\(package.name)` is already installed.")
//            return
//        }

//        let isProject = engine.arguments.flag("project")
//        if isProject {
//            package.link(into: engine.projectsURL, removeable: true)
//        }

    }
}
