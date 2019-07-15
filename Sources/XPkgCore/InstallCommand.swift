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

        // check for an existing local package with the url
        if let package = manifest.package(named: packageSpec) {
            output.log("Package `\(package.name)` is already installed.")
            return
        }

        let package = XPkg.PackageManifest(name: packageSpec, version: "1.0.0", path: ".", url: url.path, dependencies: [])
        var updatedManifest = manifest
        updatedManifest.dependencies.append(package)
        engine.saveManifest(manifest: updatedManifest)
        
        let checkManifest = engine.loadManifest()
        if checkManifest.dependencies.count <= manifest.dependencies.count {
            output.log("Couldn't add `\(packageSpec)`.")
            engine.saveManifest(manifest: manifest)
            return
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

        let cleanup = {
            engine.saveManifest(manifest: manifest)
        }

        let pkg = Package(manifest: package)
        engine.attempt(action: "Install", cleanup: cleanup) {
//            if !rerun {
//                try package.clone(engine: engine)
//                if let name = engine.arguments.option("as") {
//                    try package.rename(as: name, engine: engine)
//                }
//                try package.save()
//            }
            try pkg.run(action: "install", engine: engine)
        }
    }
}
