import AppKit
import XCTest
@testable import Waraq

/// Phase 9.9 — user-chosen primary display persistence + fallback.
final class WaraqPrimaryStoreTests: XCTestCase {
    @MainActor
    func testDefaultsToNSScreenMain() {
        let saved = WaraqPrimaryStore.chosenHardwareID
        defer { WaraqPrimaryStore.chosenHardwareID = saved }

        WaraqPrimaryStore.chosenHardwareID = nil
        XCTAssertEqual(
            WaraqPrimaryStore.currentPrimaryDisplayID(),
            NSScreen.main?.displayIDForTest
        )
    }

    @MainActor
    func testRoundTripsChosenID() {
        let saved = WaraqPrimaryStore.chosenHardwareID
        defer { WaraqPrimaryStore.chosenHardwareID = saved }

        let testID = "test-vendor-model-serial-\(UUID().uuidString)"
        WaraqPrimaryStore.chosenHardwareID = testID
        XCTAssertEqual(WaraqPrimaryStore.chosenHardwareID, testID)
    }

    @MainActor
    func testFallsBackWhenChosenNotConnected() {
        let saved = WaraqPrimaryStore.chosenHardwareID
        defer { WaraqPrimaryStore.chosenHardwareID = saved }

        WaraqPrimaryStore.chosenHardwareID =
            "nonexistent-hw-id-\(UUID().uuidString)"
        // Chosen display isn't connected, so it falls back to main.
        XCTAssertEqual(
            WaraqPrimaryStore.currentPrimaryDisplayID(),
            NSScreen.main?.displayIDForTest
        )
    }
}

private extension NSScreen {
    var displayIDForTest: CGDirectDisplayID? {
        deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID
    }
}
