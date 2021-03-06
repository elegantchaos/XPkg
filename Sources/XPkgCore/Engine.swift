// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Files
import Foundation
import Logger
import Runner
import XPkgPackage

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    func synchronousDataTask(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

public class Engine: CommandEngine {
    let jsonChannel: Channel
    let fileManager = FileManager.default
    
    var defaultOrgs = ["elegantchaos", "samdeane"] // TODO: read from preference
    
    public required init(options: CommandShellOptions) {
        jsonChannel = Logger("json", handlers: [Logger.stdoutHandler])
        super.init(options: options)
    }
    
    public override class var abstract: String {
        return "Cross Platform Package Manager."
    }
    
    public override class var subcommands: [ParsableCommand.Type] {
        return [
            InitCommand.self,
            CheckCommand.self,
            InstallCommand.self,
            LinkCommand.self,
            ListCommand.self,
            PathCommand.self,
            ReinstallCommand.self,
            RemoveCommand.self,
            RenameCommand.self,
            RevealCommand.self,
            UpdateCommand.self,
        ]
    }
    
    internal var xpkgURL: URL {
        let localPath = ("~/.local/share/xpkg" as NSString).expandingTildeInPath as String
        let localURL = URL(fileURLWithPath: localPath).resolvingSymlinksInPath()
        
        if fileManager.fileExists(at: localURL) {
            return localURL
        } else {
            let globalURL = URL(fileURLWithPath: "/usr/local/share/xpkg").resolvingSymlinksInPath()
            if fileManager.fileExists(atPath: globalURL.path) {
                return globalURL
            }
        }
        
        try? fileManager.createDirectory(at: localURL, withIntermediateDirectories: true)
        return localURL
    }
    
    internal var xpkgCodeURL: URL {
        return xpkgURL.appendingPathComponent("code")
    }
    
    /// Returns the latest semantic version tag for the remote repo.
    /// If the tag contains a "v", we return it along with the number.
    /// - Parameter url: the url of the repo
    internal func latestVersion(_ url: URL) -> String? {
        let runner = Runner(for: gitURL)
        let arguments = ["ls-remote", "--tags", "--refs", "--sort=v:refname", "--exit-code", url.absoluteString ]
        
        var error = ""
        let callback = Runner.Mode.callback({ text in
            error.append(text)
            // TODO: filter out some known errors and exit or prompt for the user to fix them?
        })
        
        // TODO: add a timeout?
        guard let result = try? runner.sync(arguments: arguments, stdoutMode: .capture, stderrMode: callback), result.status == 0 else {
            return nil
        }
        
        guard let tag = result.stdout.split(separator: "/").last else {
            return ""
        }
        
        guard tag.contains(".") else {
            return ""
        }
        
        return String(tag.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    typealias RepoValidator = (URL) -> String?
    
    func validate(_ remote: URL) -> String? {
        let version = latestVersion(remote)
        return version?.replacingOccurrences(of: "v", with: "")
    }
    
    internal var gitLooksLikeItIsSetup: Bool {
        let hosts = FileManager.default.locations.home.folder(".ssh").file("known_hosts")
        return hosts.asText?.contains("github.com") ?? false
    }
    
    /// Given a package spec, try to find a URL and latest version for the package.
    /// The spec can be one of:
    /// - a full URL - which is used directly
    /// - an unqualified package name - we try to make a github URL using one of the default organisations
    /// - a qualified org/package page - we try to make this into a github URL
    /// - Parameter package: the package spec
    /// - Parameter skipValidation: whether to perform online validation; provided for testing
    internal func remotePackageURL(_ package: String, validator: RepoValidator? = nil) -> (URL, String?) {
        let validate = validator ?? { url in self.validate(url) }
        
        if let remote = URL(string: package), let version = validate(remote) {
            return (remote, version)
        }
        
        var paths = ["\(package)"]
        for org in defaultOrgs {
            paths.append("\(org)/\(package)")
            paths.append("\(org)/xpkg-\(package)")
        }

        var methods = ["https://github.com/"]
        if gitLooksLikeItIsSetup {
            // try git@ first if it looks like github is in the known hosts etc
            methods.insert("git@github.com:", at: 0)
        }

        for method in methods {
            for path in paths {
                if let remote = URL(string: "\(method)\(path)"), let version = validate(remote) {
                    return (remote, version)
                }
            }
        }
        
        return (URL(string: "git@github.com:\(package)")!, nil)
    }
    
    internal var vaultURL: URL {
        let url = xpkgURL.appendingPathComponent("vault")
        
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    internal var gitURL: URL {
        return URL(fileURLWithPath: "/usr/bin/git")
    }
    
    internal var swiftURL: URL {
        return URL(fileURLWithPath: "/usr/bin/swift")
    }
    
    internal var projectsURL: URL {
        let paths = ["~/Projects", "~/Developer/Projects"]
        for path in paths {
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            if FileManager.default.fileExists(at: url) {
                return url
            }
        }
        return URL(fileURLWithPath: "Projects")
    }
    
    func swift(_ arguments: [String], failureMessage: @autoclosure () -> String = "") -> Runner.Result? {
        let runner = Runner(for: swiftURL, cwd: vaultURL)
        do {
            let result = try runner.sync(arguments: arguments)
            if result.status != 0 {
                let message = failureMessage()
                if !message.isEmpty { output.log(message) }
                verbose.log(result.stderr)
            }
            return result
        } catch {
            let message = failureMessage()
            if !message.isEmpty { output.log(message) }
            verbose.log(error)
            return nil
        }
    }
    
    func attempt(action: String, cleanup: (() throws -> Void)? = nil, block: () throws -> ()) {
        verbose.log(action)
        do {
            try block()
        } catch {
            try? cleanup?()
            output.log("\(action) failed.\n\(error)")
        }
    }
    
    func tryToLoadManifest() -> Package? {
        do {
            let cachedURL = vaultURL.appendingPathComponent("Package.json")
            var json = ""
            if let cached = try? String(contentsOf: cachedURL, encoding: .utf8) {
                verbose.log("Loading cached manifest.")
                json = cached
            }
            
            if json.isEmpty {
                verbose.log("Loading manifest from \(vaultURL).")
                guard let showResult = swift(["package", "show-dependencies", "--format", "json"]), showResult.status == 0 else {
                    verbose.log("Failed to fetch dependencies.")
                    return nil
                }
                
                json = showResult.stdout
                if let index = json.firstIndex(of: "{") {
                    json.removeSubrange(json.startIndex ..< index)
                }
                
                jsonChannel.log(json)
                verbose.log(showResult.stderr)
                
                try? json.write(to: cachedURL, atomically: true, encoding: .utf8)
            }
            
            let decode = JSONDecoder()
            if let data = json.data(using: .utf8) {
                do {
                    let manifest = try decode.decode(Package.self, from: data)
                    return manifest
                }
            }
            verbose.log("Failed to decode manifest.")
        } catch {
            verbose.log(error)
        }
        
        verbose.log("Failed to load manifest.")
        return nil
    }
    
    func loadManifest() -> Package {
        let manifest = tryToLoadManifest()
        return manifest ?? Package(name: "XPkgVault")
    }
    
    func saveManifest(manifest: Package) {
        var dependencies = ""
        var products = ""
        
        for package in manifest.dependencies {
            let version = package.version
            if version.isEmpty || version == "unspecified" {
                dependencies.append("        .package(url: \"\(package.url)\", Version(1,0,0)...Version(10000,0,0)),\n")
            } else {
                dependencies.append("        .package(url: \"\(package.url)\", from:\"\(version)\"),\n")
            }
            products.append("              .product(name: \"\(package.name)-xpkg-hooks\", package: \"\(package.name)\"),\n")
        }
        
        let manifestText = """
            // swift-tools-version:5.2

            import PackageDescription
            let package = Package(
                name: "XPkgVault",
                platforms: [
                     .macOS(.v10_15)
                 ],
                products: [
                ],
                dependencies: [
            \(dependencies)
                ],
                targets: [
                  .target(
                      name: "Installed",
                      dependencies: [
            \(products)
                        ]
                  ),
                ]
            )
            """
        
        let url = vaultURL.appendingPathComponent("Package.swift")
        do {
            try createInstalledSourceStub()
            try manifestText.write(to: url, atomically: true, encoding: .utf8)
            removeManifestCache()
        } catch {
            verbose.log(error)
        }
    }
    
    func createInstalledSourceStub() throws {
        let sourcesURL = vaultURL.appendingPathComponent("Sources").appendingPathComponent("Installed")
        try? fileManager.createDirectory(at: sourcesURL, withIntermediateDirectories: true, attributes: nil)
        let mainURL = sourcesURL.appendingPathComponent("main.swift")
        try "".write(to: mainURL, atomically: true, encoding: .utf8)
    }
    
    func removeManifestCache() {
        let cachedURL = vaultURL.appendingPathComponent("Package.json")
        try? fileManager.removeItem(at: cachedURL)
    }
    
    func updateManifest(from: Package, to: Package) -> Package? {
        saveManifest(manifest: to)
        if let resolved = tryToLoadManifest() {
            return resolved
        }
        
        // backup failed manifest for debugging
        let manifestURL = vaultURL.appendingPathComponent("Package.swift")
        let failedURL = vaultURL.appendingPathComponent("Failed Package.swift")
        try? fileManager.moveItem(at: manifestURL, to: failedURL)
        
        // revert
        saveManifest(manifest: from)
        return nil
    }
    
    func processUpdate(from: Package, to: Package) {
        let (_, before) = from.allPackages
        let (after, _) = to.allPackages
        
        let beforeSet = Set<Package>(before)
        for package in after {
            if !beforeSet.contains(package) {
                do {
                    if try package.run(action: "install", engine: self) {
                        output.log("Added \(package.name).")
                    }
                } catch {
                    output.log("Install action for \(package.name) failed.")
                }
            }
        }
        
        let afterSet = Set<Package>(after)
        for package in before {
            if !afterSet.contains(package) {
                do {
                    if try package.run(action:"remove", engine: self) {
                        output.log("Removed \(package.name).")
                    }
                } catch {
                    output.log("Remove action for \(package.name) failed.")
                }
            }
        }
    }
    
    func forEachPackage(_ block: (Package) -> ()) -> Bool {
        let manifest = loadManifest()
        if manifest.dependencies.count == 0 {
            return false
        }
        for package in manifest.dependencies {
            block(package)
        }
        return true
    }
    
    /**
     Return a package structure for an existing package, if it exists
     */
    
    func possiblePackage(named name: String, manifest: Package) -> Package? {
        return manifest.package(named: name)
    }
    
    /**
     Return a package structure for an existing package that was specified as
     an argument.
     */
    
    func existingPackage(from packageName: String, manifest: Package) -> Package {
        guard let package = possiblePackage(named: packageName, manifest: manifest) else {
            output.log("Package \(packageName) is not installed.")
            exit(1)
        }
        
        return package
    }
    
    func exit(_ code: Int32) -> Never {
        Logger.defaultManager.flush()
        Foundation.exit(code)
    }
    
    func remoteNameForCwd() -> String {
        let runner = Runner(for: gitURL)
        if let result = try? runner.sync(arguments: ["remote", "get-url", "origin"]) {
            if result.status == 0 {
                return result.stdout.trimmingCharacters(in: CharacterSet.newlines)
            }
        }
        return ""
    }
    
    func localRepoForCwd()-> String {
        let runner = Runner(for: gitURL)
        if let result = try? runner.sync(arguments: ["rev-parse", "--show-toplevel"]) {
            if result.status == 0 {
                return result.stdout.trimmingCharacters(in: CharacterSet.newlines)
            }
        }
        return ""
    }
    
    func gitUserName() -> String? {
        let runner = Runner(for: gitURL)
        if let result = try? runner.sync(arguments: ["config", "--global", "user.name"]) {
            if result.status == 0 {
                return result.stdout.trimmingCharacters(in: CharacterSet.newlines)
            }
        }
        return nil
    }
}
