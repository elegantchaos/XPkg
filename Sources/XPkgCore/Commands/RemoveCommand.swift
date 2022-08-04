// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation
import Runner

public struct RemoveCommand: ParsableCommand {
    @Argument(help: "The package to remove.") var packageName: String
    @Flag(help: "Force the removal of the package even if there are local changes.") var force = false
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a package."
    )

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        let output = engine.output
        
        let manifest = try engine.loadManifest()
        let package = try engine.existingPackage(from: packageName, manifest: manifest)

        var safeToDelete = force
        if !safeToDelete {
            switch package.status(engine: engine) {
            case .unknown:
                output.log("Failed to check \(package.name) status - it might be modified or un-pushed. Use --force to force deletion.")
            case .pristine:
                safeToDelete = true
            case .modified:
                output.log("Package \(package.name) is modified. Use --force to force deletion.")
            case .uncommitted:
                output.log("Package \(package.name) has no commits. Use --force to force deletion.")
            case .ahead:
                output.log("Package \(package.name) has un-pushed commits. Use --force to force deletion.")
            case .untracked:
                output.log("Package \(package.name) is not tracking remotely or may have un-pushed commits. Use --force to force deletion.")
            }
        }

        // try to unlink the package
        if safeToDelete {
            safeToDelete = package.unedit(engine: engine)
        }

        if safeToDelete {
            // remove the package from the manifest
            var updatedManifest = manifest
            updatedManifest.remove(package: package)
            
            // run the remove action for any packages removed
            engine.processUpdate(from: manifest, to: updatedManifest)
            
            // try to write the updated manifest
            let resolved = try engine.updateManifest(from: manifest, to: updatedManifest)

            // check that the count went down
            guard resolved.dependencies.count < manifest.dependencies.count else {
                output.log("Couldn't remove `\(package.name)`.")
                return
            }
            
            output.log("Package \(package.name) removed.")
        }

        //
        //        // check the git status
        //        if package.installed {
        //        } else {
        //            // local directory seems to be missing - also safe to delete in that case
        //            safeToDelete = true
        //        }
        //
        //        if safeToDelete {
        
    }
}
