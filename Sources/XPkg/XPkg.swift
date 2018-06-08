// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, xx/yy/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Arguments

public class XPkg {
    public init() {

    }

    public func run(arguments: Arguments) {
        if let command = getCommand(arguments: arguments) {
            command.run(arguments: arguments)
        }
    }

    internal func getCommand(arguments: Arguments) -> Command? {
        if arguments.isCommand("install") {
            return InstallCommand()
        }

        return nil
    }
}
