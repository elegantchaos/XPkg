// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation

public class XPkg {
    let arguments: Arguments

    public init(arguments: Arguments) {
        self.arguments = arguments
    }

    public func run() {
        if let command = getCommand() {
            command.run(xpkg: self)
        }
    }

    internal func getCommand() -> Command? {
        if arguments.command("install") {
            return InstallCommand()
        }

        return nil
    }

    internal func vaultURL() -> URL {
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
}
