// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 12/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger

typealias ManifestCommand = [String]

struct Manifest: Codable {
    let install: [ManifestCommand]?
    let remove: [ManifestCommand]?
    let updating: [ManifestCommand]?
    let updated: [ManifestCommand]?
}

struct PackageInfo: Codable {
    let version = 1
    let name: String
    let remote: URL
    let local: URL
    let linked: Bool
    let removeable: Bool
}

class Package {
    var fileManager: FileManager
    var name: String
    var linked = false
    var removeable = false
    var global = false
    var local: URL
    let remote: URL
    var store: URL

    /**
    Init from an existing entry in the vault.

    Will fail if there is no such entry.
    */

    init?(name: String, vault: URL, fileManager: FileManager = FileManager.default) {
        let store = vault.appendingPathComponent(name)
        let infoURL = store.appendingPathComponent("info.json")
        let decoder = JSONDecoder()

        guard let data = try? Data(contentsOf: infoURL), let info = try? decoder.decode(PackageInfo.self, from: data) else {
            return nil
        }

        self.name = name
        self.store = store
        self.remote = info.remote
        self.local = info.local
        self.linked = info.linked
        self.removeable = info.removeable
        self.fileManager = fileManager
    }

    /**
    Init a new package record.
    */

    init(remote: URL, vault: URL, fileManager: FileManager = FileManager.default) {
        let nameURL = (remote.pathExtension == "git") ? remote.deletingPathExtension() : remote
        let name = nameURL.lastPathComponent
        self.name = name
        self.remote = remote
        self.store = vault.appendingPathComponent(name)
        self.fileManager = fileManager

        // is the package already linked locally?
        let infoURL = store.appendingPathComponent("info.json")
        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: infoURL), let info = try? decoder.decode(PackageInfo.self, from: data) {
            self.local = info.local
            self.linked = info.linked
            self.removeable = info.removeable
        } else {
            self.local = self.store.appendingPathComponent("local")
        }
    }

    /**
    Link package to an existing folder.
    */

    func link(to existing: URL, removeable: Bool, useLocalName: Bool = false) {
        self.local = existing
        self.linked = true
        self.removeable = removeable
        if useLocalName {
            self.name = existing.lastPathComponent
            self.store = store.deletingLastPathComponent().appendingPathComponent(name)
        }
    }

    /**
    Link package into an external container.
    */

    func link(into container: URL, removeable: Bool) {
        self.local = container.appendingPathComponent(name)
        self.linked = true
        self.removeable = removeable
    }

    /**
    Save the package info locally.
    */

    func save() throws {
        let encoder = JSONEncoder()
        let info = PackageInfo(name: name, remote: remote, local: local, linked: linked, removeable: removeable)
        if let data = try? encoder.encode(info) {
            try fileManager.createDirectory(at: store, withIntermediateDirectories: true)
            let infoURL = store.appendingPathComponent("info.json")
            try data.write(to: infoURL)
        }
    }


    /**
    Remove the package.
    */

    func remove() throws {
        if removeable {
            try fileManager.removeItem(at: local)
        }

        try fileManager.removeItem(at: store)
    }


    /**
    Reveal the package in the Finder/Desktop.
    */

    func reveal(store showStore: Bool) {
        let container = showStore ? store : local

        #if canImport(NSApplication)
        // TODO: use NSWorkspace on the Mac
        #else
        let runner = Runner(cwd: container)
        let _ = try? runner.sync(URL(fileURLWithPath: "/usr/bin/env"), arguments: ["xdg-open", "."])
        #endif
    }

    /**
    Does the store contain an entry for this package?
    */

    var registered: Bool {
        return fileManager.fileExists(at: store)
    }

    /**
    Does the package exist locally?
    */

    var installed: Bool {
        return fileManager.fileExists(at: local)
    }

    /**
    The directory to use for binary links.
    By default we use the user's local bin.
    */

    var binURL: URL {
        if (global) {
            return URL(fileURLWithPath: "/usr/local/bin")
        } else {
            let localBin = "~/.local/bin" as NSString
            return URL(fileURLWithPath: localBin.expandingTildeInPath)
        }
    }

    /**
    Clone the package into its local destination.
    */

    func clone(engine: XPkg) throws {
        let container = local.deletingLastPathComponent()
        try fileManager.createDirectory(at: container, withIntermediateDirectories: true)

        let runner = Runner(cwd: container)
        let gitArgs = ["clone", remote.absoluteString, local.path]
        let result = try runner.sync(engine.gitURL, arguments: gitArgs)
        if result.status == 0 {
            engine.output.log("Package \(name) installed.")
        } else {
            engine.output.log("Failed to install \(name).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }

    /**
    Run commands listed in the .xpkg file for a given action.
    */

    func run(action: String, engine: XPkg) throws {
        let url = local.appendingPathComponent(".xpkg.json")
        if fileManager.fileExists(atPath: url.path) {
            let decoder = JSONDecoder()
            if let manifest = try? decoder.decode(Manifest.self, from: Data(contentsOf: url)) {
                switch (action) {
                case "install": try run(commands: manifest.install, engine: engine)
                case "remove": try run(commands: manifest.remove, engine: engine)
                default:
                    engine.output.log("Unknown action \(action).")
                }
            } else {
                engine.output.log("Couldn't decode manifest.")
            }

        }
    }

    /**
    Run a list of commands.
    */

    func run(commands: [ManifestCommand]?, engine: XPkg) throws {
        if let commands = commands {
            for command in commands {
                if command.count > 0 {
                    let tool = command[0]
                    switch(tool) {
                        case "link":    builtin(link: command, engine: engine)
                        case "unlink":  builtin(unlink: command, engine: engine)
                        default:        try external(command: tool, arguments: Array(command.dropFirst()), engine: engine)
                    }
                }
            }
        }
    }

    func links(from arguments: [String]) -> (String, URL, URL) {
        let name = arguments[1]
        let linked = local.appendingPathComponent(name)
        let link = (arguments.count > 2) ? URL(expandedFilePath: arguments[2]) : binURL.appendingPathComponent(name)
        return (name, link, linked)
    }

    func external(command: String, arguments: [String], engine: XPkg) throws {
        // var executable = URL(expandedFilePath: command).absoluteURL
        print(command)
        print(local)
        var executable = URL(fileURLWithPath: command, relativeTo: local).absoluteURL
        print(executable)
        var args = arguments
        if !fileManager.fileExists(at: executable) {
            executable = URL(fileURLWithPath: "/usr/bin/env")
            args.insert(command, at: 0)
        }

        let runner = Runner(cwd: local)
        let result = try runner.sync(executable, arguments: args)
        if result.status == 0 {
            engine.output.log(result.stdout)
        } else {
            engine.output.log("Failed to run \(command).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }

    /**
    Run the built-in link command.
    */

    func builtin(link arguments: [String], engine: XPkg) {
        if arguments.count > 1 {
            let (name, link, linked) = links(from: arguments)
            engine.attempt(action: "Link (\(name) as \(link))") {
                let backup = link.appendingPathExtension("backup")
                if !fileManager.fileExists(at: backup) {
                    if fileManager.fileExists(at: link) {
                        try fileManager.moveItem(at: link, to: backup)
                    }
                }
                try fileManager.createDirectory(at: link.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.createSymbolicLink(at: link, withDestinationURL: linked)
            }
        }
    }

    /**
    Run the built-in unlink command.
    */

    func builtin(unlink arguments: [String], engine: XPkg) {
        if arguments.count > 1 {
            let (name, link, linked) = links(from: arguments)
            engine.attempt(action: "Unlink") {
                print(name, link, linked)
                if fileManager.fileIsSymLink(at: link) {
                    try fileManager.removeItem(at: link)
                    let backup = link.appendingPathExtension("backup")
                    if fileManager.fileExists(at: backup) {
                        try fileManager.moveItem(at: backup, to: link)
                    }
                }
            }
        }
    }

    /**
    Update the package.
    */

    func update(engine: XPkg) {
        engine.output.log("Updating \(name)")
    }
}
