// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Runner
import Logger

public struct InstalledPackage {
    
    public typealias ManifestCommand = [String]
    public typealias ManifestLink = [String]
    
    struct Manifest: Codable {
        let install: [ManifestCommand]?
        let remove: [ManifestCommand]?
        let updating: [ManifestCommand]?
        let updated: [ManifestCommand]?
        let links: [ManifestLink]?
        let dependencies: [String]?
    }

    let local: URL
    let output: Channel
    let verbose: Channel

    public init(local: URL, output: Channel, verbose: Channel) {
        self.local = local
        self.output = output
        self.verbose = verbose
    }
    
    public init(fromCommandLine arguments: [String]) {
        guard arguments.count > 3 else {
            exit(1)
        }
        
//        let command = arguments[0]
//        let name = arguments[1]

        let localPath = arguments[2]
        let localURL = URL(fileURLWithPath: localPath)
        
        self.local = localURL
        self.output = Logger.stdout
        self.verbose = Channel("verbose")
    }
    
    public func performAction(fromCommandLine arguments: [String], links: [ManifestLink], commands: [ManifestLink] = []) throws {
        let action = arguments[3]
        switch action {
        case "install":
            manageLinks(creating: links)
            try run(commands: commands)

        case "remove":
            try run(commands: commands)
            manageLinks(removing: links)
            
        default:
            output.log("Unrecognised action \(action).")
        }

    }
    /**
     The directory to use for binary links.
     By default we use the user's local bin.
     */
    
    var binURL: URL {
//        if (global) {
//            return URL(fileURLWithPath: "/usr/local/bin")
//        } else {
            let localBin = "~/.local/bin" as NSString
            return URL(fileURLWithPath: localBin.expandingTildeInPath)
//        }
    }
    
    /**
     Given a link specifier in the form: [localPath]. or [localPath, linkPath],
     return a triple: (localName, linkURL, localURL).
     
     If only the localPath is suppled, the link is created in the bin folder (either
     ~/.local/bin or /usr/local/bin, depending on which mode we're in), using the same
     name as the file it's linking to.
     
     If both paths are supplied, we expand ~ etc in the link file path.
     */
    
    public func resolve(link spec: [String]) -> (String, URL, URL) {
        let name = spec[0]
        let linked = local.appendingPathComponent(name)
        let link = (spec.count > 1) ? URL(expandedFilePath: spec[1]) : binURL.appendingPathComponent(name)
        return (name, link, linked)
    }

    public func attempt(action: String, cleanup: (() throws -> Void)? = nil, block: () throws -> ()) {
        verbose.log(action)
        do {
            try block()
        } catch {
            try? cleanup?()
            output.log("\(action) failed.\n\(error)")
        }
    }

    /**
     Run through a list of linkSpecs and create each one.
     */
    
    public func manageLinks(creating links:[ManifestLink]?) {
        let fileManager = FileManager.default
        if let links = links {
            for link in links {
                let (name, linkURL, linkedURL) = resolve(link: link)
                attempt(action: "Link (\(name) as \(linkURL))") {
                    let backup = linkURL.appendingPathExtension("backup")
                    if !fileManager.fileExists(at: backup) {
                        if fileManager.fileExists(at: linkURL) {
                            try fileManager.moveItem(at: linkURL, to: backup)
                        }
                    }
                    try fileManager.createDirectory(at: linkURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: linkedURL)
                }
            }
        }
    }
    
    /**
     Run through a list of linkSpecs and remove each one.
     */
    
    public func manageLinks(removing links:[ManifestLink]?) {
        let fileManager = FileManager.default
        if let links = links {
            for link in links {
                let (_, linkURL, _) = resolve(link: link)
                attempt(action: "Unlink \(linkURL)") {
                    if fileManager.fileIsSymLink(at: linkURL) {
                        try fileManager.removeItem(at: linkURL)
                        let backup = linkURL.appendingPathExtension("backup")
                        if fileManager.fileExists(at: backup) {
                            try fileManager.moveItem(at: backup, to: linkURL)
                        }
                    }
                }
            }
        }
    }
    
    /**
     Run an external command.
     */
    
    func external(command: String, arguments: [String]) throws {
        let fileManager = FileManager.default
        // var executable = URL(expandedFilePath: command).absoluteURL
        var args = arguments
        var executable = local.appendingPathComponent(command)
        if !fileManager.fileExists(at: executable) {
            executable = URL(expandedFilePath: command)
        }
        if !fileManager.fileExists(at: executable) {
            executable = URL(fileURLWithPath: "/usr/bin/env")
            args.insert(command, at: 0)
        }
        
        let runner = Runner(for: executable, cwd: local)
        let result = try runner.sync(arguments: args)
        if result.status == 0 {
            output.log(result.stdout)
        } else {
            output.log("Failed to run \(command).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }
    
    
    /**
     Run commands listed in the .xpkg file for a given action.
     */
    
    public func run(legacyAction action: String, config url: URL) throws {
        let decoder = JSONDecoder()
        if let manifest = try? decoder.decode(Manifest.self, from: Data(contentsOf: url)) {
            switch (action) {
            case "install":
                manageLinks(creating: manifest.links)
                try run(commands: manifest.install)
                
            case "remove":
                try run(commands: manifest.remove)
                manageLinks(removing: manifest.links)
                
            default:
                output.log("Unknown action \(action).")
            }
        } else {
            output.log("Couldn't decode manifest.")
        }
    }
    
    /**
     Run a list of commands.
     */
    
    public func run(commands: [ManifestCommand]?) throws {
        if let commands = commands {
            for command in commands {
                if command.count > 0 {
                    let tool = command[0]
                    let arguments = Array(command.dropFirst())
                    switch(tool) {
                    case "link":    manageLinks(creating: [arguments])
                    case "unlink":  manageLinks(removing: [arguments])
                    default:        try external(command: tool, arguments: arguments)
                    }
                }
            }
        }
    }

}
