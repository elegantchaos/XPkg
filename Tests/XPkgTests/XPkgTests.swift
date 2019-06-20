// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import XCTest
import Arguments
@testable import XPkgCore


class XPkgTests: XCTestCase {
    func testName() {
        let arguments = Arguments(program: "xpkg")
        let engine = XPkg(arguments: arguments)
        engine.defaultOrgs = ["testorg"]
        let remote = engine.remotePackageURL("test", skipValidation: true)
        XCTAssertEqual(remote, URL(string: "git@github.com:testorg/test"))
    }

    func testNameOrg() {
        let arguments = Arguments(program: "xpkg")
        let engine = XPkg(arguments: arguments)
        let remote = engine.remotePackageURL("someorg/someproj")
        XCTAssertEqual(remote, URL(string: "git@github.com:someorg/someproj"))
    }

    func testRepo() {
        let arguments = Arguments(program: "xpkg")
        let engine = XPkg(arguments: arguments)
        let remote = engine.remotePackageURL("git@mygit.com:someorg/someproj")
        XCTAssertEqual(remote, URL(string: "git@mygit.com:someorg/someproj"))
    }

    static var allTests = [
        ("testName", testName),
        ("testNameOrg", testNameOrg),
        ("testRepo", testRepo),
    ]
}
