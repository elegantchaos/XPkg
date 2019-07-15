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

        // resolve the spec to a full url
        output.log("Searching for package \(packageSpec)...")
        let url = engine.remotePackageURL(packageSpec)
        var updatedManifest = manifest
        
        // add the package to the manifest
        let package = Package(url: url, version: "1.0.0")
        updatedManifest = manifest
        updatedManifest.add(package: package)
        
        // try to write the update
        guard let resolved = engine.updateManifest(from: manifest, to: updatedManifest), resolved.dependencies.count > manifest.dependencies.count else {
            output.log("Couldn't add `\(packageSpec)`.")
            return
        }

        // link into project if requested
        if engine.arguments.flag("project"), let package = resolved.package(withURL: url) {
            let name = engine.arguments.option("as") ?? package.name
            let linkURL = engine.projectsURL.appendingPathComponent(name)
            package.link(to: linkURL, engine: engine)
        }

        // if it wrote ok, run the install actions for any new packages
        engine.processUpdate(from: manifest, to: resolved)
        
    }
}
