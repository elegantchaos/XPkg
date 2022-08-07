// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CommandShell
import Foundation
import XPkgCore
import SemanticVersion

var info: [String:Any] = [:]

if let url = Bundle.module.url(forResource: "EmbeddedInfo", withExtension: "plist"),
   let data = try? Data(contentsOf: url),
   let decoded = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
   let dictionary = decoded as? [String:Any] {
    info = dictionary
}

info[.versionInfoKey] = CurrentVersion.string
info[.buildInfoKey] = CurrentVersion.build

CommandShell<Engine>.main(info: info)

