// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 13/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public extension URL {
    init(expandedFilePath original: String) {
        let expanded = NSString(string: original).expandingTildeInPath
        self.init(fileURLWithPath: expanded)
    }
}

public extension FileManager {
    func fileExists(at url: URL) -> Bool {
        return fileExists(atPath: url.path)
    }
    
    func fileIsSymLink(at url: URL) -> Bool {
        if let attributes = try? attributesOfItem(atPath: url.path) {
            if let type = attributes[FileAttributeKey.type] as? FileAttributeType {
                return type == .typeSymbolicLink
            }
        }
        return false
    }

}
