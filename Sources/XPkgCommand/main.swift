// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XPkg
import Arguments

let doc = """
Cross Platform Package Manager.

Usage:
    xpkg check [<package>]
    xpkg install <package> [--project] [--as=<name>]
    xpkg link [<package> <path>]
    xpkg list [--compact | --verbose | --oneline]
    xpkg path (<package> | --self) [--store]
    xpkg reinstall <package>
    xpkg remove <package> [--force]
    xpkg rename <package> <name>
    xpkg reveal <package> [--store] [--path]
    xpkg update [<package> | --self]
    xpkg (-h | --help)
    xpkg --version

Arguments:
    <package>                           The package to install/remove/modify.
    <path>                              Path to local package.
    <name>                              Name to use locally for a package.

Options:
    -h, --help                          Show this text.
    -logs <logs>                        Specify all log channels to enable.
    -logs+ <logs>                       Specify additional log channels to enable.
    -logs- <logs>                       Specify log channels to disable.
    --store                             Use internal store, rather than the package root.
    --compact                           Produces minimal output.
    --oneline                           Produces output on a single line.
    --verbose                           Produces extra output.
    --rerun                             Re-run the install actions, even if already installed.
    --self                              Perform the action on xpkg itself, rather than an installed package.

Examples:
    xpkg install MyPackage              # Install a package from the default github org
    xpkg install MyOrg/MyPackage        # Install a package from the a github org
    xpkg install git@srv.com:path.git   # Install a package from an explicit git repo



"""

let arguments = Arguments(documentation: doc, version: XPkgCommandMetadata.version)
let engine = XPkg(arguments: arguments)
engine.run()
