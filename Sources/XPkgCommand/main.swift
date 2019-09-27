// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XPkgCore
import Arguments
import Logger
import Foundation

let doc = """
Cross Platform Package Manager.

Usage:
    xpkg check [<package>] [--verbose]
    xpkg init [--verbose]
    xpkg install <package> [--project [--as=<name>]]
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

func infoPlist() -> [String:String] {
    if let handle = dlopen(nil, RTLD_LAZY) {
        defer { dlclose(handle) }
        
        if let ptr = dlsym(handle, MH_EXECUTE_SYM) {
            var size: UInt = 0
            let mhExecHeaderPtr = ptr.assumingMemoryBound(to: mach_header_64.self)
            if let ptr = getsectiondata(mhExecHeaderPtr, "__TEXT", "__Info_plist", &size) {
                let data = Data(bytesNoCopy: ptr, count: Int(size), deallocator: .none)
                do {
                    let info = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    return info as? [String:String] ?? [:]
                } catch {
                }
            }
        }
    }
    return [:]
}

let info = infoPlist()
let version: String
if let name = info["CFBundleDisplayName"], let short = info["CFBundleShortVersionString"], let build = info["CFBundleVersion"] {
    version = "\(name) \(short) (\(build))."
} else {
    version = "Unknown version."
}

let filtered = Manager.removeLoggingOptions(from: CommandLine.arguments)
let arguments = Arguments(documentation: doc, version: version, arguments: filtered)
let engine = Engine(arguments: arguments)
engine.run()
Logger.defaultManager.flush()
