import AppKit
import XCTest
@testable import DropShot

final class DragPanelTriggerTests: XCTestCase {

    func testShowsForNewDragWithFiles() {
        var trigger = DragPanelTrigger(lastChangeCount: 1)
        XCTAssertTrue(trigger.shouldShow(changeCount: 2, types: [.fileURL]))
    }

    func testIgnoresNewDragWithoutFiles() {
        var trigger = DragPanelTrigger(lastChangeCount: 1)
        XCTAssertFalse(trigger.shouldShow(changeCount: 2, types: [.string]))
    }

    // The drag pasteboard keeps the last drag's contents, so an unchanged
    // count means no new drag has started.
    func testIgnoresStalePasteboard() {
        var trigger = DragPanelTrigger(lastChangeCount: 2)
        XCTAssertFalse(trigger.shouldShow(changeCount: 2, types: [.fileURL]))
    }

    func testShowsOnlyOncePerDrag() {
        var trigger = DragPanelTrigger(lastChangeCount: 1)
        XCTAssertTrue(trigger.shouldShow(changeCount: 2, types: [.fileURL]))
        XCTAssertFalse(trigger.shouldShow(changeCount: 2, types: [.fileURL]))
    }
}
