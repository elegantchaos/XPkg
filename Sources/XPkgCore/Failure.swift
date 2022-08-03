// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/08/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

enum Failure: Error {
    case packageNotInstalled(String)
    case couldntLoadDependencyData
    case errorLoadingDependencyData(Int32, String)
    case couldntDecodeDependencyData
    case badPackageSpec(String)
    case packageMissingHooks(String, String)
}

extension Failure: CustomStringConvertible {
    var description: String {
        switch self {
            case .packageNotInstalled(let name):
                return "Package “\(name)” is not installed."

            case .packageMissingHooks(let product, let package):
                return "Package “\(package)” doesn't have an \(product) product. It is probably not an XPkg package."

            case .errorLoadingDependencyData(let code, let error):
                return "Swift returned error \(code) whilst fetching dependency data: \(error)"
            case .couldntLoadDependencyData:
                return "The dependency data is missing."
                
            case .couldntDecodeDependencyData:
                return "The depedency data is corrupt."
                
            case .badPackageSpec(let spec):
                return "Can't find package “\(spec)”. Packages should be in the form “user/package” or “oganisation/package”."
        }
    }
}
