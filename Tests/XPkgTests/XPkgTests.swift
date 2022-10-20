// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
// Created by Sam Deane, 08/06/2018.
// All code (c) 2018 - present day, Elegant Chaos Limited.
// For licensing terms, see http://elegantchaos.com/license/liberal/.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import CommandShell
@testable import XPkgCore

class XPkgTests: XCTestCase {
    var matched = false
    
    func validator(expecting: String) -> Engine.RepoValidator {
        self.matched = false
        return { url in
            if url.absoluteString == expecting {
                self.matched = true
              return "1.0.0"
            } else {
                return nil
            }
        }
    }
    
    var info: [String:Any] = [:]
    func testName() {
        let engine = Engine(options: CommandShellOptions(), info: info)
        engine.defaultOrgs = ["testorg"]
        let _ = try! engine.remotePackageURL("test", validator: validator(expecting: "git@github.com:testorg/test"))
        XCTAssertTrue(self.matched)
    }

    func testNameOrg() {
        let engine = Engine(options: CommandShellOptions(), info: info)
        let _ = try! engine.remotePackageURL("someorg/someproj", validator: validator(expecting: "git@github.com:someorg/someproj"))
        XCTAssertTrue(self.matched)
    }

    func testRepo() {
        let engine = Engine(options: CommandShellOptions(), info: info)
        let _ = try! engine.remotePackageURL("git@mygit.com:someorg/someproj", validator: validator(expecting: "git@mygit.com:someorg/someproj"))
        XCTAssertTrue(self.matched)
    }
}
