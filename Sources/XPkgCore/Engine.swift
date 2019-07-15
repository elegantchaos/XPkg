// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments
import Foundation
import Logger
import Runner

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

public class XPkg {
    let arguments: Arguments
    let output = Logger.stdout
    let verbose = Logger("verbose")
    var defaultOrgs = ["elegantchaos", "samdeane"] // TODO: read from preference

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
        let localPath = ("~/.local/share/xpkg-spm" as NSString).expandingTildeInPath as String
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

    internal func remoteExists(_ remote: String) -> Bool {
        let runner = Runner(for: gitURL)
        if let result = try? runner.sync(arguments: ["ls-remote", remote, "--exit-code"]) {
            return result.status == 0
        }
        return false
    }

    internal func remotePackageURL(_ package: String, skipValidation: Bool = false) -> URL {
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
                // iterate default orgs, looking for a repo that exists
                // if we don't find any, we just default to the unqualified package - knowing that it's probably wrong
                var found: URL? = nil
                for org in defaultOrgs {
                    let repo = "git@github.com:\(org)/\(package)"
                    if skipValidation || remoteExists(repo) {
                        found = URL(string: repo)
                        output.log("Found remote package \(org)/\(package).")
                        break
                    }
                }
                remote = found ?? URL(string: "git@github.com:\(package)")
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

    internal var swiftURL: URL {
        return URL(fileURLWithPath: "/usr/bin/swift")
    }
    
    internal var projectsURL: URL {
        return URL(fileURLWithPath: ("~/Projects" as NSString).expandingTildeInPath)
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
        let runner = Runner(for: swiftURL, cwd: vaultURL)
        if let result = try? runner.sync(arguments: ["package", "show-dependencies", "--format", "json"]) {
            if result.status == 0 {
                let decode = JSONDecoder()
                if let data = result.stdout.data(using: .utf8) {
                    do {
                        let manifest = try decode.decode(Package.self, from: data)
                        return manifest
                    } catch {
                        print(error)
                    }
                }
            }
        }
        return nil
    }

    func loadManifest() -> Package {
        let manifest = tryToLoadManifest()
        return manifest ?? Package(name: "XPkgVault")
    }
    
    func saveManifest(manifest: Package) {
        let manifestHead = """
// swift-tools-version:5.0
import PackageDescription
let package = Package(
    name: "XPkgVault",
    products: [
    ],
    dependencies: [

"""
            
        let manifestTail = """
    ],
    targets: [
    ]
)
"""

        var manifestText = manifestHead
        for package in manifest.dependencies {
            manifestText.append("       .package(url: \"\(package.url)\", from: \"\(package.version)\"),\n")
        }
        manifestText.append(manifestTail)
        let url = vaultURL.appendingPathComponent("Package.swift")
        try? manifestText.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func updateManifest(from: Package, to: Package) -> Package? {
        saveManifest(manifest: to)
        if let resolved = tryToLoadManifest() {
            return resolved
        }
            
        // revert
        saveManifest(manifest: from)
        return nil
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
    Return a package structure for an existing package that was specified as
    an argument.
    */

    func existingPackage(from argument: String = "package", manifest: Package) -> Package {
        let packageName = arguments.argument(argument)
        guard let package = manifest.package(named: packageName) else {
            output.log("Package \(packageName) is not installed.")
            exit(1)
        }

        return package
    }
    
    func exit(_ code: Int32) -> Never {
        Logger.defaultManager.flush()
        Foundation.exit(code)
    }
}
