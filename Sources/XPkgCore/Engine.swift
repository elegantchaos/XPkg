// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Expressions
import Files
import Foundation
import Logger
import Runner
import SemanticVersion
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
    static let missingProductPattern = try! NSRegularExpression(pattern: #"'vault': product '(.*)' required by package 'vault' target 'Installed' not found in package '(.*)'."#)
//                                                                         'vault': product 'Logger-xpkg-hooks' required by package 'vault' target 'Installed' not found in package 'Logger'
    let jsonChannel: Channel
    let fileManager = FileManager.default
    
    var defaultOrgs = ["elegantchaos", "samdeane"] // TODO: read from preference
    
    public required init(options: CommandShellOptions, info: [String:Any]?) {
        jsonChannel = Channel("json", handlers: [Channel.stdoutHandler])
        super.init(options: options, info: info)
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
            RebuildCommand.self,
            ReinstallCommand.self,
            RemoveCommand.self,
            RenameCommand.self,
            RepairCommand.self,
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
    internal func remotePackageURL(_ package: String, validator: RepoValidator? = nil) throws -> (URL, String?) {
        let validate = validator ?? { url in self.validate(url) }
        
        if let remote = URL(string: package), let version = validate(remote) {
            return (remote, version)
        }
        
        let tryPrefixing = !package.starts(with: "xpkg-")
        let containsSlash = package.contains("/")
        
        var paths = ["\(package)"]
        if !containsSlash {
            for org in defaultOrgs {
                paths.append("\(org)/\(package)")
                if tryPrefixing {
                    paths.append("\(org)/xpkg-\(package)")
                }
            }
        }

        var methods = ["https://github.com/"]
        if gitLooksLikeItIsSetup {
            // try git@ first if it looks like github is in the known hosts etc
            methods.insert("git@github.com:", at: 0)
        }

        for method in methods {
            for path in paths {
                verbose.log("Trying \(method)\(path)")
                if let remote = URL(string: "\(method)\(path)"), let version = validate(remote) {
                    return (remote, version)
                }
            }
        }
        
        throw Failure.badPackageSpec(package)
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
    
    var dependencyCacheURL: URL {
        vaultURL.appendingPathComponent("Dependencies.json")
    }
    
    var manifestURL: URL {
        vaultURL.appendingPathComponent("Package.swift")
    }
    
    func dependencyData(readCache: Bool, writeCache: Bool) throws -> Data {
        let cachedURL = dependencyCacheURL
        
        if readCache, let cached = try? Data(contentsOf: cachedURL) {
            verbose.log("Loaded cached dependencies.")
            return cached
        }

        verbose.log("Reading dependencies from \(manifestURL).")
        guard let showResult = swift(["package", "show-dependencies", "--format", "json"]) else {
            throw Failure.couldntLoadDependencyData
        }
        
        let code = showResult.status
        let output = showResult.stderr
        guard code == 0 else {
            let range = NSRange(location: 0, length: output.count)
            let matches = Self.missingProductPattern.matches(in: output, range: range)
            if let match = matches.first {
                let product = (output as NSString).substring(with: match.range(at: 1))
                let package = (output as NSString).substring(with: match.range(at: 2))
                throw Failure.packageMissingHooks(product, package)
            }

            throw Failure.errorLoadingDependencyData(code, output)
        }
            
        var json = showResult.stdout
        if let index = json.firstIndex(of: "{") {
            json.removeSubrange(json.startIndex ..< index)
        }
            
        jsonChannel.log(json)
            
        if writeCache {
            verbose.log("Saved cached dependencies.")
            try? json.write(to: cachedURL, atomically: true, encoding: .utf8)
        }
        
        return json.data(using: .utf8)!
    }
    
    func emptyManifest() -> Package {
        Package(name: "XPkgVault")
    }
    
    func loadManifest(readCache: Bool = true, writeCache: Bool = true, createIfMissing: Bool = false) throws -> Package {

        if !fileManager.fileExists(atURL: manifestURL), createIfMissing {
            return emptyManifest()
        }
        
        let data = try dependencyData(readCache: readCache, writeCache: writeCache)

        do {
            let decode = JSONDecoder()
            let manifestPackage = try decode.decode(Package.self, from: data)
            return manifestPackage
        } catch {
            verbose.log("Failed to decode manifest.")
            verbose.log(error)
            throw Failure.couldntDecodeDependencyData
        }
    }
    
    func saveManifestAndRemoveCachedDependencies(manifest: Package) {
        var dependencies = ""
        var products = ""
        
        for package in manifest.dependencies {
            let version = package.version
            if version.isEmpty || version == "unspecified" {
                dependencies.append("        .package(url: \"\(package.url)\", Version(0,0,1)...Version(10000,0,0)),\n")
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
            removeDependencyCache()
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
    
    func removeDependencyCache() {
        try? fileManager.removeItem(at: dependencyCacheURL)
    }
    
    func updateManifest(from oldPackage: Package, to newPackage: Package) throws -> Package {
        let backupURL = manifestURL.appendingPathExtension("backup")
        do {
            try fileManager.moveItem(at: manifestURL, to: backupURL)
            verbose.log("Backed up manifest to \(backupURL).")
        } catch {
            verbose.log("Failed to backup existing manifest.")
        }
        
        defer {
            verbose.log("Removing backup if still present.")
            try? fileManager.removeItem(at: backupURL)
        }
        
        saveManifestAndRemoveCachedDependencies(manifest: newPackage)
        
        do {
            let resolved = try loadManifest()
            return resolved
        } catch {
            // backup failed manifest for debugging
            let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let failedURL = vaultURL.appendingPathComponent("Failed Package \(date).swift")
            try? fileManager.moveItem(at: manifestURL, to: failedURL)
            verbose.log("Failed to load updated manifest. Saved manifest as \(failedURL) for inspection.")

            do {
                try fileManager.moveItem(at: backupURL, to: manifestURL)
                verbose.log("Restored manifest from backup.")
            } catch {
                verbose.log("Failed to restore previous manifest. Will attempt to recreate it.")
                saveManifestAndRemoveCachedDependencies(manifest: oldPackage)
            }
            
            throw error
        }
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
    
    func forEachPackage(_ block: (Package) -> ()) throws -> Bool {
        let manifest = try loadManifest()
        
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
    
    func existingPackage(from packageName: String, manifest: Package) throws -> Package {
        guard let package = possiblePackage(named: packageName, manifest: manifest) else {
            throw Failure.packageNotInstalled(packageName)
        }
        
        return package
    }
    
//    func fail(_ failure: Failure) -> Never {
//        let message: String
//        let code: Int32
//
//        switch failure {
//            case .packageNotInstalled(let packageName):
//                message = "Package \(packageName) is not installed."
//                code = 1
//                
//            case .couldntLoadManifest:
//                message = "Manifest is missing or corrupt."
//                code = 2
//        }
//        
//        output.log(message)
//        exit(code)
//    }
    
    func exit(_ code: Int32) -> Never {
        Manager.shared.flush()
        Foundation.exit(code)
    }
    
    func remoteOriginForCwd() -> String {
        return remoteOrigin() ?? ""
    }

    func remoteOrigin(forLocalURL url: URL? = nil) -> String? {
        let runner = Runner(for: gitURL, cwd: url)
        guard let result = try? runner.sync(arguments: ["remote", "get-url", "origin"]), result.status == 0 else { return nil }
        return result.stdout.trimmingCharacters(in: CharacterSet.newlines)
    }
    
    func remoteURL(forLocalURL url: URL?) -> URL? {
        guard let origin = remoteOrigin(forLocalURL: url) else { return nil }
        return URL(string: origin)
        
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
    
    /// Pull the latest version of XPkg, then re-run the bootstrap script
    /// to build & install it.
    func update() throws {
        output.log("Updating xpkg.")
        let url = xpkgURL
        let codeURL = url.appendingPathComponent("code")
        let runner = Runner(for: gitURL, cwd: codeURL)
        let result = try runner.sync(arguments: ["pull"])
        output.log(result.stdout)

        try runBootstrap()
    }

    /// Run the bootstrap script.
    /// This will rebuild Xpkg and (re)install any essential links.
    func runBootstrap() throws {
        output.log("Rebuilding.")
        let codeURL = xpkgURL.appendingPathComponent("code")
        let bootstrapURL = codeURL.appendingPathComponent(".bin").appendingPathComponent("bootstrap")
        let bootstrapRunner = Runner(for: bootstrapURL, cwd: codeURL)
        let result = try bootstrapRunner.sync()
        output.log(result.stdout)
    }

    /// Install a package.
    func install(packageSpec: String, asProject: Bool = false, asName: String? = nil, linkTo: URL? = nil) throws {
        // load the existing manifest; if it's missing we'll create a new empty one
        let manifest = try loadManifest(createIfMissing: true)
        
        // do a quick check first for an existing local package with the name/spec
        if let existingPackage = manifest.package(matching: packageSpec) {
            output.log("Package `\(existingPackage.name)` is already installed.")
            return
        }
        
        // resolve the spec to a full url and a version
        output.log("Searching for package \(packageSpec)...")
        let (url, version) = try remotePackageURL(packageSpec)
        
        // now we have a full spec, check again to see if it's already installed
        if let existingPackage = manifest.package(matching: url.deletingPathExtension().path) {
            output.log("Package `\(existingPackage.name)` is already installed. Use `\(name) upgrade \(packageSpec)` to upgrade it to the latest version.")
            return
        }

        if let version = version, !version.isEmpty {
            output.log("Installing \(url.path) \(version).")
        } else {
            output.log("Installing \(url.path).")
        }

        // add the package to the manifest
        verbose.log("Adding package to manifest.")
        let newPackage = Package(url: url, version: version ?? "")
        var updatedManifest = manifest
        updatedManifest.add(package: newPackage)
        
        // try to write the update
        verbose.log("Writing manifest.")
        let resolved = try updateManifest(from: manifest, to: updatedManifest)
        
        guard resolved.dependencies.count > manifest.dependencies.count else {
            output.log("Couldn't add `\(packageSpec)`.")
            return
        }
        
        // link into project if requested
        guard let installedPackage = resolved.package(withURL: url) else {
            output.log("Couldn't find package.")
            verbose.log(resolved.dependencies.map({ $0.url }))
            return
        }

        let specifyLink = asProject || (linkTo != nil)
        let name = asName ?? installedPackage.name
        var linkURL: URL? = nil
        if specifyLink {
            let pathURL = linkTo ?? projectsURL.appendingPathComponent(name)
            verbose.log("Linking package into \(pathURL.path).")
            linkURL = pathURL
        } else {
            verbose.log("Linking package into Packages/.")
        }
        
        installedPackage.edit(at: linkURL, engine: self)
        
        // if it wrote ok, run the install actions for any new packages
        // we need to reload the package once again as it has moved
        let reloadedManifest = try loadManifest(readCache: false, writeCache: true)
        
        verbose.log("Running actions for new packages.")
        processUpdate(from: manifest, to: reloadedManifest)
    }
    
    /// Returns the version of the package, according to `git describe`
    /// - Parameter engine: The current engine.
    func currentVersion(forLocalURL url: URL) -> String? {
        let runner = Runner(for: gitURL, cwd: url)
        guard let result = try? runner.sync(arguments: ["describe", "--tags"]), result.status == 0 else { return nil }
        let fullVersion = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = SemanticVersion(fullVersion)
        return version.isInvalid ? nil : version.asString(dropTrailingZeros: false)
    }

    /// Given a local directory, try to make a Package.
    /// This will work if it's a git directory with an origin remote set,
    /// and a tagged version.
    func reconstructPackage(from localURL: URL) -> Package? {
        guard localURL.isFileURL else { return nil }
        
        guard let remoteURL = remoteURL(forLocalURL: localURL) else { return nil }
        let version = currentVersion(forLocalURL: localURL) ?? "unspecified"
        
        return Package(localURL: localURL, remoteURL: remoteURL, version: version)
    }
    
    /// Attempt to repair a corrupt manifest.
    /// We look in the Packages/ folder inside the value. Each folder in there should be a package,
    /// so we make a new empty manifest, and then try to install each package in turn.
    func repair() throws {
        let packages = fileManager.locations.folder(for: vaultURL).folder("Packages")
        if packages.exists {
            var manifest = emptyManifest()
            try packages.forEach(filter: .folders, recursive: false) { folder in
                if let package = reconstructPackage(from: folder.url) {
                    manifest.add(package: package)
                }
            }
            saveManifestAndRemoveCachedDependencies(manifest: manifest)
        }
    }
}

extension SemanticVersion {
    public func asString(dropTrailingZeros: Bool = true) -> String {
        guard !isInvalid else {
            return "<invalid>"
        }

        guard !isUnknown else {
            return "<unknown>"
        }
        
        var string = "\(major).\(minor)"
        if !dropTrailingZeros || patch != 0 {
            string += ".\(patch)"
        }
        return string
    }

}
