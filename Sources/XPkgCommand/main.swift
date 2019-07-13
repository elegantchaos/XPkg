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
    xpkg check [<package>]
    xpkg install <package> [--project]
    xpkg link [<package> <path>]
    xpkg list [--compact | --verbose | --oneline]
    xpkg path (<package> | --self) [--store]
    xpkg reinstall <package>
    xpkg remove <package> [--force] [--verbose]
    xpkg reveal <package> [--store] [--path]
    xpkg update [<package> | --self]
    xpkg (-h | --help)
    xpkg --version

Arguments:
    <package>                           The package to install/remove/modify.
    <path>                              Path to local package.

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

func infoPlist() -> [String:String] {
    if let handle = dlopen(nil, RTLD_LAZY) {
        defer { dlclose(handle) }
        
        if let ptr = dlsym(handle, MH_EXECUTE_SYM) {
            let mhExecHeaderPtr = ptr.assumingMemoryBound(to: mach_header_64.self)
            var size: UInt = 0
            let ptr = getsectiondata(mhExecHeaderPtr, "__TEXT", "__Info_plist", &size)
            let data = Data(bytesNoCopy: ptr!, count: Int(size), deallocator: .none)
            do {
                let info = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                return info
            } catch {
            }
        }
    }
    return [:]
}

print("blah")
let info = infoPlist
let version = info["CFBundleShortVersionString"] as? String
let filtered = Manager.removeLoggingOptions(from: CommandLine.arguments)
let arguments = Arguments(documentation: doc, version: version ?? "unknown", arguments: filtered)
let engine = XPkg(arguments: arguments)
engine.run()
Logger.defaultManager.flush()
