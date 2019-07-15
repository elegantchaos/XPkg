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

        let candidates = [
            URL(string: packageSpec)!,
            URL(string:"git@github.com:\(packageSpec)")!,
            URL(string:"git@gihub.com:elegantchaos/\(packageSpec)")!,
            URL(string:"git@gihub.com:samdeane/\(packageSpec)")!
        ]
        
        var found: URL? = nil
        var updatedManifest = manifest
        for candidate in candidates {
            output.log("Trying `\(candidate.path)`.")
            let package = XPkg.PackageManifest(name: "", version: "1.0.0", path: ".", url: candidate.path, dependencies: [])
            updatedManifest = manifest
            updatedManifest.dependencies.append(package)
            engine.saveManifest(manifest: updatedManifest)
            
            updatedManifest = engine.loadManifest()
            if updatedManifest.dependencies.count > manifest.dependencies.count {
                output.log("Found pakacge at `\(candidate.path)`.")
                found = candidate
                break
            }
        }

        if found == nil {
            output.log("Couldn't add `\(packageSpec)`.")
            engine.saveManifest(manifest: manifest)
            return
        }

        if let package = updatedManifest.package(withURL: found!) {
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
