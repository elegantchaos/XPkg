// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments

protocol Command {
    func run(xpkg: XPkg)
}

struct InstallCommand: Command {
    func run(xpkg: XPkg) {
        let vault = xpkg.vaultURL()

        let package = xpkg.arguments.argument("package")

        print("installing \(package) into \(vault)")
    }
}
