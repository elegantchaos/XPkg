// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation

public struct InstallCommand: ParsableCommand {
    @Argument(help: "The package to install.") var packageSpec: String
    @Flag(name: .customLong("project"), help: "Install in the projects folder, and not as a package.") var asProject = false
    @Option(name: .customLong("as"), help: "The name to use for the package.") var asName: String?
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "install",
        abstract: "Install a package."
    )
    

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        try InstallCommand.install(engine: engine, packageSpec: packageSpec, asProject: asProject, asName: asName)
    }
    
    static func install(engine: Engine, packageSpec: String, asProject: Bool = false, asName: String? = nil, linkTo: URL? = nil) throws {
        let output = engine.output

        // load the existing manifest; if it's missing we'll create a new empty one
        let manifest = try engine.loadManifest(createIfMissing: true)
        
        // do a quick check first for an existing local package with the name/spec
        if let existingPackage = manifest.package(matching: packageSpec) {
            output.log("Package `\(existingPackage.name)` is already installed.")
            return
        }
        
        // resolve the spec to a full url and a version
        output.log("Searching for package \(packageSpec)...")
        let (url, version) = try engine.remotePackageURL(packageSpec)
        
        // now we have a full spec, check again to see if it's already installed
        if let existingPackage = manifest.package(matching: url.deletingPathExtension().path) {
            output.log("Package `\(existingPackage.name)` is already installed. Use `\(engine.name) upgrade \(packageSpec)` to upgrade it to the latest version.")
            return
        }

        if let version = version, !version.isEmpty {
            engine.output.log("Installing \(url.path) \(version).")
        } else {
            engine.output.log("Installing \(url.path).")
        }

        // add the package to the manifest
        engine.verbose.log("Adding package to manifest.")
        let newPackage = Package(url: url, version: version ?? "")
        var updatedManifest = manifest
        updatedManifest.add(package: newPackage)
        
        // try to write the update
        engine.verbose.log("Writing manifest.")
        let resolved = try engine.updateManifest(from: manifest, to: updatedManifest)
        
        guard resolved.dependencies.count > manifest.dependencies.count else {
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
        let reloadedManifest = try engine.loadManifest(readCache: false, writeCache: true)
        
        engine.verbose.log("Running actions for new packages.")
        engine.processUpdate(from: manifest, to: reloadedManifest)
        
    }
    
}
