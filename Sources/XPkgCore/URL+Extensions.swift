// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/08/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public extension URL {
    var normalizedGitURL: URL {
        let urlNoGitExtension = pathExtension == "git" ? deletingPathExtension() : self
        let string = urlNoGitExtension.absoluteString.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
        return URL(string: string)!
    }
    
    var asPackageSpec: String? {
        let components = normalizedGitURL.pathComponents
        let count = components.count
        guard count > 1 else { return nil }
        let specComponents = [components[count - 2], components[count - 1]]
        return specComponents.joined(separator: "/")
    }
}
