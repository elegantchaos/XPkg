// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation

public struct ReinstallCommand: ParsableCommand {
    @Argument(help: "The package to reinstall.") var packageName: String
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "reinstall",
        abstract: "Re-install the package. This is the equivalent of doing remove <package> followed by install <package>."
    )

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        let manifest = try engine.loadManifest()
        let package = try engine.existingPackage(from: packageName, manifest: manifest)

        engine.attempt(action: "Reinstalling \(package.name).") {
            do {
                engine.verbose.log("Uninstalling \(package.name)")
                if try package.run(action: "remove", engine: engine) {
                    engine.output.log("Removed \(package.name).")
                }
                engine.verbose.log("Installing \(package.name)")
                if try package.run(action: "install", engine: engine) {
                    engine.output.log("Reinstalled \(package.name).")
                }
            } catch {
                engine.output.log("Reinstall of \(package.name) failed.")
                engine.verbose.log(error)
            }
        }
    }
}
