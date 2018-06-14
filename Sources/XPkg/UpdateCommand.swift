// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 14/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

struct UpdateCommand: Command {
    func run(engine: XPkg) {
        let output = engine.output

        if engine.arguments.command("self") {
            updateSelf(engine: engine)
        } else if engine.arguments.argument("package") == "" {
            let _ = engine.forEachPackage { (package) in
                package.update(engine: engine)
            }
        } else {
            let package = engine.existingPackage()
            package.update(engine: engine)
        }
    }

    func updateSelf(engine: XPkg) {
        let url = engine.xpkgURL
        let codeURL = url.appendingPathComponent("code")
        let runner = Runner(cwd: codeURL)
        let bootstrapURL = codeURL.appendingPathComponent(".bin").appendingPathComponent("bootstrap")
        runner.sync(bootstrapURL)
    }

}
