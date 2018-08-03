// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 02/08/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

struct RenameCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output
        let package = engine.existingPackage()
        let oldName = package.name
        let name = engine.arguments.argument("new-name")
        if package.installed {
            do {
                try package.rename(as: name, engine: engine)
                engine.output.log("Renamed \(oldName) as \(name).")
            } catch {
                engine.output.log("Failed to rename \(oldName) as \(name).\n\(error).")
            }
        }
    }
}
