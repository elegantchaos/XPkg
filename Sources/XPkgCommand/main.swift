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

let year = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
info[.versionInfoKey] = CurrentVersion.string
info[.buildInfoKey] = CurrentVersion.build
info[.copyrightInfoKey] = "Copyright © \(year) Elegant Chaos. All rights reserved."

CommandShell<Engine>.main(info: info)

