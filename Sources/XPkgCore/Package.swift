// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 12/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger
import Runner

enum RenameError: Error {
    case renameStore(from: URL, to: URL)
    case renameLocal
    case saveInfo
}

struct PackageInfo: Codable {
    let version = 1
    let name: String
    let remote: URL
    let local: URL
    let linked: Bool
    let removeable: Bool
}

enum PackageError: Error, CustomStringConvertible {
    case failedToClone(repo: String)

    var description: String {
        switch self {
        case .failedToClone(let repo):
            return "Couldn't clone from \(repo)."
        }
    }
}

enum PackageStatus {
    case pristine
    case modified
    case ahead
    case unknown
    case untracked
    case uncommitted
}

struct Package: Decodable {
    let name: String
    let version: String
    let path: String
    let url: String
    var dependencies: [Package]

    init(url: URL, version: String) {
        self.name = ""
        self.path = ""
        self.url = url.absoluteString
        self.version = version
        self.dependencies = []
    }

    init(name: String) {
        self.name = name
        self.path = ""
        self.url = ""
        self.version = ""
        self.dependencies = []
    }

    func package(matching spec: String) -> Package? {
        for package in dependencies {
            if package.name == spec {
                return package
            } else if package.url == spec {
                return package
            } else if package.remote.path == spec {
                return package
            }
        }
        return nil
    }
    
    func package(named name: String) -> Package? {
        for package in dependencies {
            if package.name == name {
                return package
            }
        }
        return nil
    }
    
    func package(withURL url: URL) -> Package? {
        let normalised = url.absoluteString.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        for package in dependencies {
            let packageNormalised = package.url.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
            if packageNormalised == normalised {
                return package
            }
        }
        return nil
    }
    
    class DepthsIndex {
        var index: [Package:Depths] = [:]

        func record(package: Package, depth: Int) {
            if let depths = index[package] {
                depths.record(depth: depth)
            } else {
                index[package] = Depths(depth: depth)
            }
        }
    }
    
    class Depths {
        var highest: Int
        var lowest: Int
        
        init(depth: Int) {
            highest = depth
            lowest = depth
        }
        
        func record(depth: Int) {
            highest = max(depth, highest)
            lowest = min(depth, lowest)
        }
    }
    
    func recordPackages(index: DepthsIndex, depth: Int) {
        for package in dependencies {
            index.record(package: package, depth: depth)
            package.recordPackages(index: index, depth: depth + 1)
        }
    }
    
    var allPackages: ([Package], [Package]) {
        let index = DepthsIndex()
        recordPackages(index: index, depth: 1)
        
        let byMostDependent = index.index.sorted { (p1, p2) -> Bool in
            return p1.value.highest > p2.value.highest
        }
        
        let byLeastDependent = index.index.sorted { (p1, p2) -> Bool in
            return p1.value.lowest < p2.value.lowest
        }

        return (byMostDependent.map({ $0.key }), byLeastDependent.map({ $0.key }))
    }
    
    mutating func add(package: Package) {
        dependencies.append(package)
    }
    
    mutating func remove(package: Package) {
        if let index = dependencies.firstIndex(where: { $0.name == package.name }) {
            dependencies.remove(at: index)
        }
    }
    
    var fileManager: FileManager { return FileManager.default }
    var linked: Bool { return false }
    var removeable: Bool { return false }
    var global: Bool { return false }
    var local: URL { return URL(fileURLWithPath: path) }
    var remote: URL { return URL(string: url)! }
    var store: URL { return URL(fileURLWithPath: path) }

    /**
    Init from an existing entry in the vault.

    Will fail if there is no such entry.
    */
//
//    init?(name: String, vault: URL, fileManager: FileManager = FileManager.default) {
//        let store = vault.appendingPathComponent(name)
//        let infoURL = store.appendingPathComponent("info.json")
//        let decoder = JSONDecoder()
//
//        guard let data = try? Data(contentsOf: infoURL), let info = try? decoder.decode(PackageInfo.self, from: data) else {
//            return nil
//        }
//
//        self.name = name
//    }
    
    /**
    Init a new package record.
    */
//
//    init(remote: URL, vault: URL) {
//        let nameURL = (remote.pathExtension == "git") ? remote.deletingPathExtension() : remote
//        let name = nameURL.lastPathComponent
//        self.name = name
////
////        // is the package already linked locally?
////        let infoURL = store.appendingPathComponent("info.json")
////        let decoder = JSONDecoder()
////        if let data = try? Data(contentsOf: infoURL), let info = try? decoder.decode(PackageInfo.self, from: data) {
////            self.local = info.local
////            self.linked = info.linked
////            self.removeable = info.removeable
////        } else {
////            self.local = Package.defaultLocalURL(for: name, in: store)
////        }
//    }

    /**
    Return the default location to use for the local (hidden) clone of a package.
    */

    static func defaultLocalURL(for name: String, in store: URL) -> URL {
        return store.appendingPathComponent("local").appendingPathComponent(name)
    }

    /**
    Link package to an existing folder.
    */

    func edit(at url: URL? = nil, engine: XPkg) {
        var args = ["package", "edit", name]
        let message: String
        if let url = url {
            args.append(contentsOf: ["--path", url.path])
            message = "Failed to link \(name) into \(url)."
        } else {
            message = "Failed to edit \(name)."
        }
        
        let _ = engine.swift(args, failureMessage: message)
    }

    /**
     Link package to an existing folder.
     */
    
    func unlink(engine: XPkg) -> Bool {
        guard let result = engine.swift(["package", "unedit", name]) else {
            engine.output.log("Failed to unlink \(name) from \(path).")
            return false
        }
        
        return result.status == 0 || result.stderr.contains("not in edit mode")
    }

//    /**
//    Link package into an external container.
//    */
//
//    func link(into container: URL, removeable: Bool) {
////        self.local = container.appendingPathComponent(name)
////        self.linked = true
////        self.removeable = removeable
//    }

    /**
    Save the package info locally.
    */

    func save() throws {
//        let encoder = JSONEncoder()
//        let info = PackageInfo(name: name, remote: remote, local: local, linked: linked, removeable: removeable)
//        if let data = try? encoder.encode(info) {
//            try fileManager.createDirectory(at: store, withIntermediateDirectories: true)
//            let infoURL = store.appendingPathComponent("info.json")
//            try data.write(to: infoURL)
//        }
    }


    /**
    Remove the package.
    */

    func remove() throws {
//        if removeable && installed {
//            try fileManager.removeItem(at: local)
//        }
//
//        try fileManager.removeItem(at: store)
    }


    /**
    Reveal the package in the Finder/Desktop.
    */

    func reveal(store showStore: Bool) {
        let container = showStore ? store : local

        #if canImport(NSApplication)
        // TODO: use NSWorkspace on the Mac
        #else
        let runner = Runner(for: URL(fileURLWithPath: "/usr/bin/env"), cwd: container)
        let _ = try? runner.sync(arguments: ["xdg-open", "."])
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
    What state is the local package in?
     */

    func status(engine: XPkg) -> PackageStatus {
        let runner = Runner(for: engine.gitURL, cwd: local)
        if let result = try? runner.sync(arguments: ["status", "--porcelain", "--branch"]) {
            engine.verbose.log(result.stdout)
            if result.status == 0 {
                let lines = result.stdout.split(separator: "\n")
                if lines.count > 0 {
                    let branch = lines[0]
                    if branch == "## No commits yet on master" {
                        return .uncommitted
                    } else {
                        let output = lines.dropFirst().joined(separator: "\n")
                        if output == "" {
                            let branchOk = branch.contains("...") || branch == "## HEAD (no branch)"
                            return branchOk ? .pristine : .untracked
                        } else if output.contains("??") || output.contains(" D ") || output.contains(" M ") || output.contains("R  ") || output.contains("A  ") {
                            return .modified
                        } else if output.contains("[ahead ") {
                            return .ahead
                        } else {
                            return .untracked
                        }
                    }
                }
            }
        }

        return .unknown
    }



    /**
    Clone the package into its local destination.
    */

    func clone(engine: XPkg) throws {
        let container = local.deletingLastPathComponent()
        try fileManager.createDirectory(at: container, withIntermediateDirectories: true)

        let runner = Runner(for: engine.gitURL, cwd: container)
        let gitArgs = ["clone", remote.absoluteString, local.path]
        let result = try runner.sync(arguments: gitArgs)
        if result.status == 0 {
            engine.output.log("Package \(name) installed.")
        } else {
            engine.output.log("Failed to install \(name).")
            engine.verbose.log("\(result.status) \(result.stdout) \(result.stderr)")
            throw PackageError.failedToClone(repo: remote.absoluteString)
        }
    }

    /**
    Update the package.
    */

    func update(engine: XPkg) {
        let runner = Runner(for: engine.gitURL, cwd: local)
        if let result = try? runner.sync(arguments: ["pull", "--ff-only"]) {
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
//        let newStore = store.deletingLastPathComponent().appendingPathComponent(newName)
//        do {
//            try fileManager.moveItem(at: store, to: newStore)
//            self.store = newStore
//        } catch {
//            throw RenameError.renameStore(from: store, to: newStore)
//        }
//
//        let oldLocal: URL
//        let newLocal: URL
//        if linked {
//            // package is linked elsewhere, so we just want to rename it
//            oldLocal = local
//            newLocal = local.deletingLastPathComponent().appendingPathComponent(newName)
//
//        } else {
//            newLocal = Package.defaultLocalURL(for: newName, in: newStore)
//
//            if local.lastPathComponent == name {
//                // package is inside the store, which has already been renamed
//                // but the local folder itself still needs to be renamed
//                oldLocal = Package.defaultLocalURL(for: name, in: newStore)
//
//            } else {
//                // package is inside store, but was previously just in a folder called "local"
//                // we want to fix things up a bit
//                let oldStyleLocal = newStore.appendingPathComponent("local")
//                oldLocal = newStore.appendingPathComponent("temp-rename")
//                try? fileManager.moveItem(at: oldStyleLocal, to: oldLocal)
//                try? fileManager.createDirectory(at: oldStyleLocal, withIntermediateDirectories: true)
//            }
//        }
//
//        do {
//            try fileManager.moveItem(at: oldLocal, to: newLocal)
//            self.local = newLocal
//        } catch {
//            throw RenameError.renameLocal
//        }
//
//        self.name = newName
    }
}

extension Package: Hashable {
    
}
