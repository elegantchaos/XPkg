// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ArgumentParser
import CommandShell
import Files
import Foundation
import Runner

public struct BootstrapCommand: ParsableCommand {
    static public var configuration: CommandConfiguration = CommandConfiguration(
        commandName: "bootstrap",
        abstract: "Install necesssary links and commands for xpkg to work correctly. This command is invoked automatically during Xpkg installation, but you can also invoke it manually to rebuild links if the installation is damaged."
    )
    
    @OptionGroup() var common: CommandShellOptions

    public init() {
    }
    
    public func run() throws {
        let engine: Engine = common.loadEngine()
        
        let shouldBackup = true
        
        let shellHooksStartup = engine.shareURL.appendingPathComponents(["shell-hooks", "startup"])
        let binURL = engine.binURL
        let functionsURL = URL(fileURLExpandingPath: "~/.config/fish/functions")
        engine.output("Installing links \(engine.isLocal ? "locally" : "globally").")

        // link the built app
        let code = engine.xpkgURL.appendingPathComponent("code")
        try link(from: code.appendingPathComponent(".build/debug/xpkg"), to: binURL.appendingPathComponent("xpkg"))

        // link extra commands
        let scripts = code.appendingPathComponent("Extras/Scripts")
        try link(from: scripts.appendingPathComponent("xpkg-dev"), to: binURL.appendingPathComponent("xpkg-dev"))
        try link(from: scripts.appendingPathComponent("uninstall"), to: binURL.appendingPathComponent("xpkg-uninstall"))

        // link in the xg alias for bash/zsh
        try link(from: scripts.appendingPathComponent("xg-bash-zsh"), to: shellHooksStartup.appendingPathComponent("xpkg"))

        // link in the xg alias for fish
        try link(from: scripts.appendingPathComponent("xg.fish"), to: functionsURL.appendingPathComponent("xg.fish"))

        engine.output("Installing shell startup hooks.")
        
        // install the shell-hooks
        let runner = Runner(for: scripts.appendingPathComponent("shell-hooks/install)"))
        var args = [root.path]
        if !shouldBackup {
            args.append("--no-backup")
        }

        runner.sync(arguments: args, stdoutMode: .passthrough, stderrMode: .passthrough)
        
        engine.output("Done.\n\nOpen a new shell / terminal window and type xpkg to get started.\n\n")

    }
    
    func link(from: URL, to: URL) throws {
        // $SUDO ln -sf "$ROOT/code/Extras/Scripts/xpkg-bash" "$STARTUP/xpkg"
        let wrapper = FileWrapper(symbolicLinkWithDestinationURL: from)
        
    }
}
