// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 28/02/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BuilderConfiguration

let settings = Settings(specs: [
    .base(
        values: [
        ],
        inherits: [
            .spec(name: "mac", filter: ["macOS"]),
            .spec(name: "debug", filter: ["debug"])
        ]
    ),
    .spec(
        name: "mac",
        values: [
          .setting("minimum-target", "macosx10.13"),
        ]
    ),
    .spec(
        name: "debug",
        values: [
          .setting("optimisation", "none")
        ]
    )
    ]
)

let configuration = Configuration(
    settings: settings,
    actions: [
        .action(name:"build", phases:[
            .buildPhase(name:"Building", target:"xpkg"),
            ]),
        .action(name:"test", phases:[
            .testPhase(name:"Testing", target:"XPkgTests"),
            ]),
        .action(name:"run", phases:[
            .actionPhase(name:"Building", action: "build"),
            .toolPhase(name:"Running", tool: "run", arguments:["xpkg"]),
            ]),
    ]
)

configuration.outputToBuilder()
