// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 20/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension Package {

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
        var args = arguments
        var executable = local.appendingPathComponent(command)
        if !fileManager.fileExists(at: executable) {
            executable = URL(expandedFilePath: command)
        }
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

}
