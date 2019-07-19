// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 19/07/2019.
// All code (c) 2019 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

struct SemanticVersion: Equatable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ string: String) {
        var version = string
        if string.first == "v" {
            version.remove(at: version.startIndex)
        }
        let items = version.split(separator: ".")
        guard items.count == 3 else {
            return nil
        }
        
        self.init(major: String(items[0]), minor: String(items[1]), patch: String(items[2]))
    }
    
    init?(major: String, minor: String, patch: String) {
        guard let iMajor = Int(major), let iMinor = Int(minor), let iPatch = Int(patch) else {
            return nil
        }

        self.major = iMajor
        self.minor = iMinor
        self.patch = iPatch
    }

    var text: String {
        return patch == 0 ? "\(major).\(minor)" : "\(major).\(minor).\(patch)"
    }

}

func <(x: SemanticVersion, y: SemanticVersion) -> Bool {
    if (x.major < y.major) {
        return true
    } else if (x.major > y.major) {
        return false
    } else if (x.minor < y.minor) {
        return true
    } else if (x.minor > y.minor) {
        return false
    } else {
        return x.patch < y.patch
    }

}
