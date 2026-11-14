import XCTest
@testable import GestureCore

final class GestureEngineTests: XCTestCase {
    func testIdleAndLeftHold() {
        var engine = GestureEngine()
        XCTAssertEqual(engine.step(), 0)
        XCTAssertTrue(engine.accept(.began(.left)))
        XCTAssertEqual(engine.step(), -1)
        XCTAssertTrue(engine.accept(.ended(.left)))
        XCTAssertEqual(engine.step(), 0)
    }

    func testRightHoldAndWrongRelease() {
        var engine = GestureEngine()
        XCTAssertTrue(engine.accept(.began(.right)))
        XCTAssertEqual(engine.step(), 1)
        XCTAssertFalse(engine.accept(.ended(.left)))
        XCTAssertEqual(engine.step(), 1)
        XCTAssertTrue(engine.accept(.ended(.right)))
        XCTAssertEqual(engine.step(), 0)
    }

    func testRejectsOverlapAndDuplicateStart() {
        var engine = GestureEngine()
        XCTAssertTrue(engine.accept(.began(.left)))
        XCTAssertFalse(engine.accept(.began(.left)))
        XCTAssertFalse(engine.accept(.began(.right)))
        XCTAssertEqual(engine.activeSide, .left)
    }
}
