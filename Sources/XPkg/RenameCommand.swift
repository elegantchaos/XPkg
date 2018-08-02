// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 02/08/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

struct RenameCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let package = engine.existingPackage()
        let name = engine.arguments.argument("new-name")

        if package.installed {
                        output.log("Renaming \(package.name) to \(name).")
        } else {
        }

        // if safeToDelete {
        //     engine.attempt(action: "Remove \(package.name)") {
        //         try package.run(action:"remove", engine: engine)
        //         try package.remove()
        //         if package.linked && !package.removeable {
        //             output.log("Package \(package.name) was linked to a local directory (\(package.local.path)). \nThe package has been uninstalled, but the linked directory was not touched.")
        //         } else {
        //             output.log("Package \(package.name) removed.")
        //         }
        //     }
        // }
    }
}
