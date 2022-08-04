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
        try engine.install(packageSpec: packageSpec, asProject: asProject, asName: asName)
    }
}
