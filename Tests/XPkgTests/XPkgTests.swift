// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import XCTest
import Arguments
@testable import XPkg


class XPkgTests: XCTestCase {
    func testSimpleName() {
        let arguments = Arguments(program: "xpkg")
        let xpkg = XPkg(arguments: arguments)
        xpkg.defaultOrg = "testorg"
        let remote = xpkg.remotePackageURL("test")
        XCTAssertEqual(remote, URL(string: "git@github.com:testorg/test"))
    }

    static var allTests = [
        ("testSimpleName", testSimpleName),
    ]
}
