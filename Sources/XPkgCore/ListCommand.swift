// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Foundation


public struct ListCommand: ParsableCommand {
    @Flag(help: "Produces output on a single line.") var oneline = false
    @Flag(help: "Produces minimal output.") var compact = false
    @Flag(help: "Produces output with extra details.") var full = false
    @OptionGroup() var common: CommandShellOptions

    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "list",
        abstract: "List the installed packages."
    )

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        if oneline {
          try listOneline(engine: engine)
        } else if compact {
            try listCompact(engine: engine)
        } else if full {
            try listFull(engine: engine)
        } else {
            try listNormal(engine: engine)
        }
    }

    func listOneline(engine: Engine) throws {
        var output: [String] = []
        let _ = try engine.forEachPackage { (package) in
            output.append(package.name)
        }
        engine.output.log(output.joined(separator: " "))
    }

    func listCompact(engine: Engine) throws {
        let gotPackages = try engine.forEachPackage { (package) in
            engine.output.log("\(package.name)")
        }
        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

    func listNormal(engine: Engine) throws {
        var gotLinked = false
        let gotPackages = try engine.forEachPackage { (package) in
            let linked = !package.local.absoluteString.contains(engine.vaultURL.absoluteString)
            let flags = linked ? "*" : " "
            gotLinked = gotLinked || linked
            let status = package.status(engine: engine)
            let statusString = status == .pristine ? "" : " (\(status))"
            engine.output.log("\(flags) \(package.name)\(statusString)")
        }


        if !gotPackages {
            engine.output.log("No packages installed.")
        } else if gotLinked {
            engine.output.log("\n(items marked with * are linked to external folders)")
        }
    }

    func listFull(engine: Engine) throws {
        let gotPackages = try engine.forEachPackage { (package) in
            let linked = !package.local.absoluteString.contains(engine.vaultURL.absoluteString)
            let location = linked ? "\(package.local.path) (linked)" : package.local.path
            let status = package.status(engine: engine)
            let version = package.currentVersion(engine: engine)
            let statusString = status == .pristine ? "" : " (\(status))\n"
            engine.output.log("\n\(package.name) (\(version))\n---------------------\n\(package.url)\n\(location)\n\(statusString)")
        }

        if !gotPackages {
            engine.output.log("No packages installed.")
        }
    }

}
