import XCTest
@testable import Reflect

final class CrisisDetectorTests: XCTestCase {

    func test_detectsDirectSelfHarmLanguage() {
        XCTAssertTrue(CrisisDetector.containsCrisisLanguage("Some days I just want to kill myself."))
    }

    func test_isCaseInsensitive() {
        XCTAssertTrue(CrisisDetector.containsCrisisLanguage("I WANT TO DIE today, I really do."))
    }

    func test_detectsSelfHarmPhrasing() {
        XCTAssertTrue(CrisisDetector.containsCrisisLanguage("I keep thinking about hurting myself when it gets bad."))
    }

    func test_ignoresOrdinaryText() {
        XCTAssertFalse(CrisisDetector.containsCrisisLanguage("Had a good day, went for a run and read a bit."))
    }

    func test_ignoresEmptyText() {
        XCTAssertFalse(CrisisDetector.containsCrisisLanguage(""))
    }

    func test_ignoresUnrelatedUseOfTriggerWord() {
        // "suicide" as a topic mentioned in passing isn't the case this needs to
        // catch precisely, but the detector is deliberately over-inclusive, so
        // this documents the tradeoff rather than asserting it's excluded.
        XCTAssertTrue(CrisisDetector.containsCrisisLanguage("Read an article about suicide prevention today."))
    }
}
