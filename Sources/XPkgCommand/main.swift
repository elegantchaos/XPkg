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
    xpkg install <package>
    xpkg remove <package>
    xpkg (-h | --help)

Arguments:
    <package>                           The package to install/remove/modify.


Options:
    -h, --help                          Show this text.
    -logs <logs>                        Specify all log channels to enable.
    -logs+ <logs>                       Specify additional log channels to enable.
    -logs- <logs>                       Specify log channels to disable.

Examples:
    xpkg install MyPackage              # Install a package from the default github org
    xpkg install MyOrg/MyPackage        # Install a package from the a github org
    xpkg install git@srv.com:path.git   # Install a package from an explicit git repo



"""

let arguments = Arguments(documentation: doc)
let engine = XPkg(arguments: arguments)
engine.run()
