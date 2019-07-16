// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

struct InstallCommand: Command {
    func run(engine: Engine) {
        let packageSpec = engine.arguments.argument("package")
        let asProject = engine.arguments.flag("project")
        let asName = engine.arguments.option("as")
        InstallCommand.install(engine: engine, packageSpec: packageSpec, asProject: asProject, asName: asName)
    }
    
    static func install(engine: Engine, packageSpec: String, asProject: Bool = false, asName: String? = nil, linkTo: URL? = nil) {
        let output = engine.output
        
        let manifest = engine.loadManifest()
        
        // do a quick check first for an existing local package with the name/spec
        if let existingPackage = manifest.package(matching: packageSpec) {
            output.log("Package `\(existingPackage.name)` is already installed.")
            return
        }
        
        // resolve the spec to a full url and a version
        output.log("Searching for package \(packageSpec)...")
        let (url, version) = engine.remotePackageURL(packageSpec)
        var updatedManifest = manifest
        if let version = version, !version.isEmpty {
            engine.output.log("Installing \(url.path) \(version).")
        } else {
            engine.output.log("Installing \(url.path).")
        }

        // add the package to the manifest
        engine.verbose.log("Adding package to manifest.")
        let newPackage = Package(url: url, version: version ?? "")
        updatedManifest = manifest
        updatedManifest.add(package: newPackage)
        
        // try to write the update
        engine.verbose.log("Writing manifest.")
        guard let resolved = engine.updateManifest(from: manifest, to: updatedManifest), resolved.dependencies.count > manifest.dependencies.count else {
            output.log("Couldn't add `\(packageSpec)`.")
            return
        }
        
        // link into project if requested
        guard let installedPackage = resolved.package(withURL: url) else {
            output.log("Couldn't find package.")
            engine.verbose.log(resolved.dependencies.map({ $0.url }))
            return
        }

        let specifyLink = asProject || (linkTo != nil)
        let name = asName ?? installedPackage.name
        var linkURL: URL? = nil
        if specifyLink {
            let pathURL = linkTo ?? engine.projectsURL.appendingPathComponent(name)
            engine.verbose.log("Linking package into \(pathURL.path).")
            linkURL = pathURL
        } else {
            engine.verbose.log("Linking package into Packages/.")
        }
        
        installedPackage.edit(at: linkURL, engine: engine)
        
        // if it wrote ok, run the install actions for any new packages
        // we need to reload the package once again as it has moved
        let reloadedManifest = engine.loadManifest()
        engine.verbose.log("Running actions for new packages.")
        engine.processUpdate(from: manifest, to: reloadedManifest)
        
    }
    
}
