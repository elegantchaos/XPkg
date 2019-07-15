// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Runner

extension Package {

    /**
    Run commands listed in the .xpkg file for a given action.
    */

    func run(action: String, engine: XPkg) throws {
        let runner = Runner(for: engine.swiftURL, cwd: engine.vaultURL)
        if let result = try? runner.sync(arguments: ["run", "\(name)-xpkg-hooks", action]) {
            print(result.stdout)
            if result.status != 0 {
                engine.output.log("Couldn't run action \(action).")
            }
        }

//
//        let url = local.appendingPathComponent(".xpkg.json")
//        if fileManager.fileExists(atPath: url.path) {
//            let decoder = JSONDecoder()
//            if let manifest = try? decoder.decode(Manifest.self, from: Data(contentsOf: url)) {
//                switch (action) {
//                case "install":
//                    links(create: manifest.links, engine: engine)
//                    try run(commands: manifest.install, engine: engine)
//
//                case "remove":
//                    try run(commands: manifest.remove, engine: engine)
//                    links(remove: manifest.links, engine: engine)
//
//                default:
//                    engine.output.log("Unknown action \(action).")
//                }
//            } else {
//                engine.output.log("Couldn't decode manifest.")
//            }
//
//        }
    }

    /**
    Run a list of commands.
    */

    func run(commands: [ManifestCommand]?, engine: XPkg) throws {
        if let commands = commands {
            for command in commands {
                if command.count > 0 {
                    let tool = command[0]
                    let arguments = Array(command.dropFirst())
                    switch(tool) {
                    case "link":    links(create: [arguments], engine: engine)
                    case "unlink":  links(remove: [arguments], engine: engine)
                    default:        try external(command: tool, arguments: arguments, engine: engine)
                    }
                }
            }
        }
    }

    /**
    Run an external command.
    */

    func external(command: String, arguments: [String], engine: XPkg) throws {
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
            engine.output.log(result.stdout)
        } else {
            engine.output.log("Failed to run \(command).\n\n\(result.status) \(result.stdout) \(result.stderr)")
        }
    }

    /**
    Given a link specifier in the form: [localPath]. or [localPath, linkPath],
    return a triple: (localName, linkURL, localURL).

    If only the localPath is suppled, the link is created in the bin folder (either
    ~/.local/bin or /usr/local/bin, depending on which mode we're in), using the same
    name as the file it's linking to.

    If both paths are supplied, we expand ~ etc in the link file path.
    */

    func resolve(link spec: [String]) -> (String, URL, URL) {
        let name = spec[0]
        let linked = local.appendingPathComponent(name)
        let link = (spec.count > 1) ? URL(expandedFilePath: spec[1]) : binURL.appendingPathComponent(name)
        return (name, link, linked)
    }

    /**
    Run through a list of linkSpecs and create each one.
    */

    func links(create links:[ManifestLink]?, engine: XPkg) {
        if let links = links {
            for link in links {
                let (name, linkURL, linkedURL) = resolve(link: link)
                engine.attempt(action: "Link (\(name) as \(linkURL))") {
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

    func links(remove links:[ManifestLink]?, engine: XPkg) {
        if let links = links {
            for link in links {
                let (_, linkURL, _) = resolve(link: link)
                engine.attempt(action: "Unlink \(linkURL)") {
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
}
