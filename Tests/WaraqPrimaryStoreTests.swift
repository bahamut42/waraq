//  Waraq - A native macOS animated wallpaper app.
//  Copyright (C) 2026 Omar A. Othman
//
//  This program is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General
//  Public License as published by the Free Software
//  Foundation, either version 3 of the License, or (at
//  your option) any later version.
//
//  This program is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the
//  implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. See the GNU General Public License
//  for more details.
//
//  You should have received a copy of the GNU General
//  Public License along with this program. If not, see
//  <https://www.gnu.org/licenses/>.
//

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
