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
        ]
    ),
    ]
)

let configuration = Configuration(
    settings: settings,
    actions: [
        .action(name:"build", phases:[
            .toolPhase(name:"Updating Metadata", tool:"metadata", arguments:["XPkgCommand"]),
            .buildPhase(name:"Building", target:"XPkgCommand"),
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
