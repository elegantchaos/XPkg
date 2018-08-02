// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation
import Logger

public class XPkg {
    let arguments: Arguments
    let output = Logger.stdout
    let verbose = Logger("verbose")
    var defaultOrg = "elegantchaos" // TODO: read from preference

    let commands: [String:Command] = [
        "check": CheckCommand(),
        "install": InstallCommand(),
        "link": LinkCommand(),
        "list": ListCommand(),
        "path": PathCommand(),
        "reinstall": ReinstallCommand(),
        "remove": RemoveCommand(),
        "rename": RenameCommand(),
        "reveal": RevealCommand(),
        "update": UpdateCommand(),
    ]

    public init(arguments: Arguments) {
        self.arguments = arguments
    }

    public func run() {
        if let command = getCommand() {
            command.run(engine: self)
        }
    }

    internal func getCommand() -> Command? {
        for command in commands {
            if arguments.command(command.key) {
                return command.value
            }
        }

        return nil
    }

    internal var xpkgURL: URL {
        let fm = FileManager.default
        let localPath = ("~/.local/share/xpkg" as NSString).expandingTildeInPath as String
        let localURL = URL(fileURLWithPath: localPath).resolvingSymlinksInPath()

        if fm.fileExists(at: localURL) {
            return localURL
        } else {
            let globalURL = URL(fileURLWithPath: "/usr/local/share/xpkg").resolvingSymlinksInPath()
            if fm.fileExists(atPath: globalURL.path) {
                return globalURL
            }
        }

        try? FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
        return localURL
    }

    internal var xpkgCodeURL: URL {
        return xpkgURL.appendingPathComponent("code")
    }

    internal func remotePackageURL(_ package: String) -> URL {
        let remote : URL?
        if package.contains("git@") {
            remote = URL(string: package)
        } else {
            let local = URL(fileURLWithPath: package)
            if FileManager.default.fileExists(at: local) {
                remote = local
            } else if package.contains("/") {
                remote = URL(string: "git@github.com:\(package)")
            } else {
                remote = URL(string: "git@github.com:\(defaultOrg)/\(package)")
            }
        }

        return remote! // assertion is that this can't fail for a properly formed package name...
    }

    internal var vaultURL: URL {
        let url = xpkgURL.appendingPathComponent("vault")

        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    internal var gitURL: URL {
        return URL(fileURLWithPath: "/usr/bin/git")
    }

    internal var projectsURL: URL {
        return URL(fileURLWithPath: ("~/Projects" as NSString).expandingTildeInPath)
    }

    func attempt(action: String, block: () throws -> ()) {
        verbose.log(action)
        do {
            try block()
        } catch {
            output.log("\(action) failed.\n\(error)")
        }
    }

    func forEachPackage(_ block: (Package) -> ()) -> Bool {
        let fm = FileManager.default
        let vault = vaultURL
        guard let items = try? fm.contentsOfDirectory(at: vault, includingPropertiesForKeys: nil), items.count > 0 else {
            return false
        }

        for item in items {
            if let package = Package(name: item.lastPathComponent, vault: vault) {
                block(package)
            }
        }
        return true
    }

    /**
    Return a package structure for an existing package that was specified as
    an argument.
    */

    func existingPackage(from argument: String = "package") -> Package {
        let packageName = arguments.argument(argument)
        guard let package = Package(name: packageName, vault: vaultURL) else {
            output.log("Package \(packageName) is not installed.")
            exit(1)
        }

        return package
    }
}
