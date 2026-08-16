//
//  SupernovaUITestsLaunchTests.swift
//  SupernovaUITests
//
//  Created by Raneem Shaalan on 02/03/1448 AH.
//

import XCTest

import XCTest

final class SupernovaSiriTests: XCTestCase {

    func testAddHomeworkShortcut() {
        XCUIDevice.shared.siriService.activate(
            voiceRecognitionText: "أضف واجب في Supernova"
        )

        sleep(5)
    }
}
