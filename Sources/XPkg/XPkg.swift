// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

public class XPkg {
    let arguments: Arguments
    var defaultOrg = "elegantchaos" // TODO: read from preference

    let commands: [String:Command] = [
        "install": InstallCommand(),
        "remove": RemoveCommand(),
        "link": LinkCommand()
    ]

    public init(arguments: Arguments) {
        self.arguments = arguments
    }

    public func run() {
        if let command = getCommand() {
            command.run(xpkg: self)
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

    internal var vaultURL: URL {
        let fm = FileManager.default
        let localPath = ("~/.config/xpkg/vault" as NSString).expandingTildeInPath as String
        let localURL = URL(fileURLWithPath: localPath).resolvingSymlinksInPath()

        if fm.fileExists(atPath: localURL.path) {
            return localURL
        } else {
            let globalURL = URL(fileURLWithPath: "/usr/local/share/xpkg/vault").resolvingSymlinksInPath()
            if fm.fileExists(atPath: globalURL.path) {
                return globalURL
            }
        }

        try? FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
        return localURL
    }

    internal func remotePackageURL(_ package: String) -> URL {
        let remote : URL?
        if package.contains("git@") {
            remote = URL(string: package)
        } else if package.contains("/") {
            remote = URL(string: "git@github.com:\(package)")
        } else {
            remote = URL(string: "git@github.com:\(defaultOrg)/\(package)")
        }

        return remote! // assertion is that this can't fail for a properly formed package name...
    }

    internal func localPackageURL(_ package: String) -> URL {
        let vault = vaultURL
        let remote = remotePackageURL(package)
        let path = remote.path.replacingOccurrences(of: "/", with: "-")
        let local = vault.appendingPathComponent(path)

        return local
    }

    internal var gitURL: URL {
        return URL(fileURLWithPath: "/usr/bin/git")
    }

    internal var projectsURL: URL {
        return URL(fileURLWithPath: ("~/Projects" as NSString).expandingTildeInPath)
    }
}
