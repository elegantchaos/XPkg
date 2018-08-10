// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 12/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger

typealias ManifestCommand = [String]
typealias ManifestLink = [String]

enum RenameError: Error {
    case renameStore
    case renameLocal
    case saveInfo
}

struct Manifest: Codable {
    let install: [ManifestCommand]?
    let remove: [ManifestCommand]?
    let updating: [ManifestCommand]?
    let updated: [ManifestCommand]?
    let links: [ManifestLink]?
    let dependencies: [String]?
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
            self.local = Package.defaultLocalURL(for: name, in: store)
        }
    }

    /**
    Return the default location to use for the local (hidden) clone of a package.
    */

    static func defaultLocalURL(for name: String, in store: URL) -> URL {
        return store.appendingPathComponent("local").appendingPathComponent(name)
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
        if removeable && installed {
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
    Update the package.
    */

    func update(engine: XPkg) {
        let runner = Runner(cwd: local)
        if let result = try? runner.sync(engine.gitURL, arguments: ["pull", "--ff-only"]) {
            if result.status == 0 {
                if result.stdout == "Already up-to-date.\n" {
                    engine.output.log("Package \(name) unchanged.")
                } else {
                    engine.output.log("Package \(name) updated.")
                }
            } else {
                engine.output.log("Failed to update \(name).\n\n\(result.status) \(result.stdout) \(result.stderr)")
            }
        } else {
            engine.output.log("Failed to launch git whilst updating \(name).")
        }
    }

    /**
    Check that the package information seems to be valid.
    */

    func check(engine: XPkg) -> Bool {
        return fileManager.fileExists(at: local)
    }

    /**
    Rename the package. If it's a project, we also rename the project folder.
    */

    func rename(as newName: String, engine: XPkg) throws {
        let newStore = store.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: store, to: newStore)
            self.store = newStore
        } catch {
            throw RenameError.renameStore
        }

        let oldLocal: URL
        let newLocal: URL
        if linked {
            // package is linked elsewhere, so we just want to rename it
            oldLocal = local
            newLocal = local.deletingLastPathComponent().appendingPathComponent(newName)

        } else {
            newLocal = Package.defaultLocalURL(for: newName, in: newStore)

            if local.lastPathComponent == name {
                // package is inside the store, which has already been renamed
                // but the local folder itself still needs to be renamed
                oldLocal = Package.defaultLocalURL(for: name, in: newStore)

            } else {
                // package is inside store, but was previously just in a folder called "local"
                // we want to fix things up a bit
                let oldStyleLocal = newStore.appendingPathComponent("local")
                oldLocal = newStore.appendingPathComponent("temp-rename")
                try? fileManager.moveItem(at: oldStyleLocal, to: oldLocal)
                try? fileManager.createDirectory(at: oldStyleLocal, withIntermediateDirectories: true)
            }
        }

        do {
            try fileManager.moveItem(at: oldLocal, to: newLocal)
            self.local = newLocal
        } catch {
            throw RenameError.renameLocal
        }

        self.name = newName
    }
}
