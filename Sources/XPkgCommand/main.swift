// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CommandShell
import ArgumentParser
import XPkgCore

CommandShell.configuration = CommandConfiguration(
    abstract: "Cross Platform Package Manager.",
    discussion: "",
    subcommands: [
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
    ],
    defaultSubcommand: nil
)

CommandShell.main()


/*
 

 let doc = """

 Usage:
     xpkg check [<package>] [--verbose]
     xpkg init [--verbose]
     xpkg install <package> [--project [--as=<name>]] [--verbose]
     xpkg link [<package> <path>] [--verbose]
     xpkg list [--compact | --full | --oneline] [--verbose]
     xpkg path (<package> | --self | --vault) [--verbose]
     xpkg reinstall <package> [--verbose]
     xpkg remove <package> [--force] [--verbose]
     xpkg rename <package> <name> [--verbose]
     xpkg reveal <package> [--path] [--verbose]
     xpkg update [<package> | --self] [--verbose]
     xpkg (-h | --help)
     xpkg --version

 Arguments:
     <package>                           The package to install/remove/modify.
     <path>                              Path to local package.
     <name>                              Name to use locally for a package.

 Options:
     -h, --help                          Show this text.
     --logs=<logs>                       Specify all log channels to enable.
     --store                             Use internal store, rather than the package root.
     --compact                           Produces minimal output.
     --oneline                           Produces output on a single line.
     --full                              Produces output with extra details.
     --rerun                             Re-run the install actions, even if already installed.
     --self                              Perform the action on xpkg itself, rather than an installed package.
     --vault                             Show the vault path.
     --verbose                           Enable additional logging.

 Examples:
     xpkg install MyPackage              # Install a package from the default github org
     xpkg install MyOrg/MyPackage        # Install a package from the a github org
     xpkg install git@srv.com:path.git   # Install a package from an explicit git repo



 """

 */
