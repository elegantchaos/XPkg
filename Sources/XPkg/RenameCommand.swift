// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 02/08/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

struct RenameCommand: Command {
    func run(engine: XPkg) {
        let package = engine.existingPackage()
        let oldName = package.name
        if package.installed {
            engine.attempt(action: "Rename") {
                let name = try engine.arguments.expectedArgument("name")
                try package.rename(as: name, engine: engine)
                try package.save()
                engine.output.log("Renamed \(oldName) as \(name).")
            }
        }
    }
}
