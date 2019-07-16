// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 14/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Runner

struct UpdateCommand: Command {
    func run(engine: Engine) {
        if engine.arguments.flag("self") {
            updateSelf(engine: engine)
        } else if engine.arguments.argument("package") == "" {
            let _ = engine.forEachPackage { (package) in
                package.update(engine: engine)
            }
        } else {
            let manifest = engine.loadManifest()
            let package = engine.existingPackage(manifest: manifest)
            package.update(engine: engine)
        }
    }

    func updateSelf(engine: Engine) {
        engine.output.log("Updating xpkg.")
        let url = engine.xpkgURL
        let codeURL = url.appendingPathComponent("code")
        let runner = Runner(for: engine.gitURL, cwd: codeURL)
        if let result = try? runner.sync(arguments: ["pull"]) {
            engine.output.log(result.stdout)
        }

        let bootstrapURL = codeURL.appendingPathComponent(".bin").appendingPathComponent("bootstrap")
        let bootstrapRunner = Runner(for: bootstrapURL, cwd: codeURL)
        if let result = try? bootstrapRunner.sync() {
            engine.output.log(result.stdout)
        }
    }

}
