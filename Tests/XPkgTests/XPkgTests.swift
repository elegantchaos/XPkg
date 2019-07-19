// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import XCTest
import Arguments
@testable import XPkgCore


class XPkgTests: XCTestCase {
    func validator(matching: String) -> Engine.RepoValidator {
        return { url in
            if url.absoluteString == matching {
              return "matched"
            } else {
                return nil
            }
        }
    }
    
    func testName() {
        let arguments = Arguments(program: "xpkg")
        let engine = Engine(arguments: arguments)
        engine.defaultOrgs = ["testorg"]
        let (_, version) = engine.remotePackageURL("test", validator: validator(matching: "git@github.com:testorg/test"))
        XCTAssertEqual(version, "matched")
    }

    func testNameOrg() {
        let arguments = Arguments(program: "xpkg")
        let engine = Engine(arguments: arguments)
        let (_, version) = engine.remotePackageURL("someorg/someproj", validator: validator(matching: "git@github.com:someorg/someproj"))
        XCTAssertEqual(version, "matched")
    }

    func testRepo() {
        let arguments = Arguments(program: "xpkg")
        let engine = Engine(arguments: arguments)
        let (_, version) = engine.remotePackageURL("git@mygit.com:someorg/someproj", validator: validator(matching: "git@mygit.com:someorg/someproj"))
        XCTAssertEqual(version, "matched")
    }

    static var allTests = [
        ("testName", testName),
        ("testNameOrg", testNameOrg),
        ("testRepo", testRepo),
    ]
}
