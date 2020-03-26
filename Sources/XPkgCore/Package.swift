// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 12/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger
import Runner
import XPkgPackage
import SemanticVersion

#if canImport(AppKit)
import AppKit
#endif

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

    static func normalize(url: URL) -> URL {
        let urlNoGitExtension = url.pathExtension == "git" ? url.deletingPathExtension() : url
        let string = urlNoGitExtension.absoluteString.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        return URL(string: string)!
    }

    
    init(url: URL, version: String) {
        self.name = url.lastPathComponent
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

    
    var global: Bool { return false }
    var local: URL { return URL(fileURLWithPath: path) }
    
    lazy var remote: URL = {
        return URL(string: url)!
    }()

    lazy var normalized: URL = {
        return Package.normalize(url: self.remote)
    }()
    
    lazy var qualified: String = {
        let components = normalized.pathComponents
        return components[1...].joined(separator: "/")
    }()

    func package(matching spec: String) -> Package? {
        let url = URL(string:spec)
        let normalised = url == nil ? spec : Package.normalize(url: url!).absoluteString
        for var package in dependencies {
            if package.name == spec {
                return package
            } else if package.qualified == spec {
                return package
            } else if package.normalized.absoluteString == normalised {
                return package
            }
        }
        return nil
    }
    
    func package(named name: String) -> Package? {
        for package in dependencies {
            if (package.name == name) || (package.name == "xpkg-\(name)") || (package.url.contains(name)) {
                return package
            }
        }
        return nil
    }
    
    func package(withURL url: URL) -> Package? {
        let normalised = Package.normalize(url: url)
        for var package in dependencies {
            if package.normalized == normalised {
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
 

    /**
    Return the default location to use for the local (hidden) clone of a package.
    */

    static func defaultLocalURL(for name: String, in store: URL) -> URL {
        return store.appendingPathComponent("local").appendingPathComponent(name)
    }

    /**
    Link package to an existing folder.
    */

    func edit(at url: URL? = nil, engine: Engine) {
        var args = ["package", "edit", name]
        let message: String
        if let url = url {
            args.append(contentsOf: ["--path", url.path])
            message = "Failed to link \(name) into \(url)."
        } else {
            message = "Failed to edit \(name)."
        }
        
        engine.removeManifestCache()
        let _ = engine.swift(args, failureMessage: message)
    }

    /**
     Link package to an existing folder.
     */
    
    func unedit(engine: Engine) -> Bool {
        engine.removeManifestCache()
        guard let result = engine.swift(["package", "unedit", name]) else {
            engine.output.log("Failed to unlink \(name) from \(path).")
            return false
        }
        
        return result.status == 0 || result.stderr.contains("not in edit mode")
    }


    /**
    Reveal the package in the Finder/Desktop.
    */

    func reveal() {
        #if canImport(AppKit)
            NSWorkspace.shared.open([local], withAppBundleIdentifier: nil, options: .async, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        #else
            let runner = Runner(for: URL(fileURLWithPath: "/usr/bin/env"), cwd: local)
            let _ = try? runner.sync(arguments: ["xdg-open", "."])
        #endif
    }

    /**
    What state is the local package in?
     */

    func status(engine: Engine) -> PackageStatus {
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

    
    /// Returns the version of the package, according to `git describe`
    /// - Parameter engine: The current engine.
    func currentVersion(engine: Engine) -> String {
        let runner = Runner(for: engine.gitURL, cwd: local)
        if let result = try? runner.sync(arguments: ["describe"]) {
            if result.status == 0 {
                return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    /// Returns the name of the branch that the package is on, or nil if it isn't on a branch.
    /// - Parameter engine: The current engine.
    func currentBranch(engine: Engine) -> String? {
        let runner = Runner(for: engine.gitURL, cwd: local)
        if let result = try? runner.sync(arguments: ["rev-parse", "--abbrev-ref", "HEAD"]) {
            engine.verbose.log("current branch: \(result.stdout)")
            if result.status == 0 {
                let branch = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                if branch != "HEAD" {
                    return branch
                }
            }
        }
        return nil
    }

    /// Returns the latest version of the package, according to the server.
    /// - Parameter engine: the engine
    func latestVersion(engine: Engine) -> String? {
        return engine.latestVersion(URL(string:url)!)
    }
    
    enum UpdateState {
        case unchanged
        case needsUpdate(to: String)
        case notOnTag
        case couldntFetchLatest
        case couldntParseLatest
    }
    
    /// Does the package need updating?
    /// If it's on a version tag, and there's a newer version available, we return the newer version.
    /// If it's on the latest version tag, or checked out to a branch, we return nil.
    /// - Parameter engine: The current context.
    func needsUpdate(engine: Engine) -> UpdateState {
        let current = currentVersion(engine: engine)
        guard !current.contains("-") else {
            let branch = currentBranch(engine: engine)
            if branch == nil {
                engine.verbose.log("\(name) is a modified version \(current).")
            } else {
                engine.verbose.log("\(name) is a modified version \(current) on branch \(branch!)")
            }
            return .notOnTag
        }

        
        guard let latest = latestVersion(engine: engine) else {
            engine.verbose.log("\(name) couldn't fetch latest version.")
            return .couldntFetchLatest
        }
        
        guard let sCurrent = SemanticVersion(current), let sLatest = SemanticVersion(latest) else {
            engine.verbose.log("\(name) couldn't parse versions.")
            return .couldntParseLatest
        }
        
        engine.verbose.log("\(name) \(current) \(latest)")
        return sCurrent < sLatest ? .needsUpdate(to: latest) : .unchanged
    }
    
    /// Checkout the package to a given branch, tag or other ref.
    /// - Parameter ref: the branch, tag, commit or ref to check out to
    /// - Parameter engine: the context
    func checkout(to ref: String, engine: Engine) {
        let runner = Runner(for: engine.gitURL, cwd: local)
        guard let result = try? runner.sync(arguments: ["checkout", ref]) else {
            engine.output.log("Couldn't checkout package \(name) to \(ref).")
            return
        }
        
        engine.verbose.log(result.stdout)
        engine.verbose.log(result.stderr)
        if result.status != 0 {
            if result.stderr.contains("The following untracked working tree files would be overwritten") {
                engine.output.log("Package \(name) has untracked files.")
            }

            engine.output.log("Couldn't update package \(name) to \(ref).")
        }
    }

    /// Fetch the latest commits.
    /// - Parameter engine: the context
    func fetch(engine: Engine) {
        let runner = Runner(for: engine.gitURL, cwd: local)
        if let result = try? runner.sync(arguments: ["fetch", "--tags"]) {
            engine.verbose.log(result.stdout)
            engine.verbose.log(result.stderr)
        }
    }
    
    /**
    Update the package.
    */

    func update(to version: String, engine: Engine) {
        engine.output.log("Updating \(name) to \(version).")

        engine.verbose.log("Uninstalling \(name).")
        if let ok = try? run(action: "remove", engine: engine), ok {
            engine.verbose.log("Removed \(name).")
        }
        
        engine.verbose.log("Updating \(name).")
        fetch(engine: engine)
        checkout(to: version, engine: engine)
        
        engine.verbose.log("Installing \(name).")
        if let ok = try? run(action: "install", engine: engine), ok {
            engine.verbose.log("Reinstalled \(name).")
        }
    }
    
    /**
    Check that the package information seems to be valid.
    */

    func check(engine: Engine) -> Bool {
        return engine.fileManager.fileExists(at: local)
    }

    /**
    Rename the package. If it's a project, we also rename the project folder.
    */

    func rename(as newName: String, engine: Engine) throws {
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
    
    func run(action: String, engine: Engine) throws -> Bool {
        do {
            // run as a new-style package
            let runner = Runner(for: engine.swiftURL, cwd: engine.vaultURL)
            let hooks = "\(name)-xpkg-hooks"
            let arguments = ["run", hooks, name, path, action]
            let result = try runner.sync(arguments: arguments)
            engine.verbose.log("\n> \(hooks) \(name) \(path) \(action)")
            if result.status == 0 {
                engine.verbose.log("stdout: \(result.stdout)")
                engine.verbose.log("stderr: \(result.stderr)\n")
                return true
            }
            
            if !result.stdout.contains("no exexcutable product") {
                engine.verbose.log("failure: \(result.status)")
                engine.verbose.log("stdout: \(result.stdout)")
                engine.verbose.log("stderr: \(result.stderr)\n")
            }
            
            // fallback to old method?
            let configURL = local.appendingPathComponent(".xpkg.json")
            if engine.fileManager.fileExists(atPath: configURL.path) {
                let installed = InstalledPackage(local: local, output: engine.output, verbose: engine.verbose)
                try installed.run(legacyAction: action, config: configURL)
                return true
            }

        } catch {
            engine.output.log("Couldn't run action \(action).")
            engine.verbose.log(error)
            throw error
        }
        
        engine.verbose.log("Ignoring \(name) as it isn't an xpkg package.")
        return false
    }
}

extension Package: Hashable {
    func hash(into hasher: inout Hasher) {
        url.hash(into: &hasher)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }
}
