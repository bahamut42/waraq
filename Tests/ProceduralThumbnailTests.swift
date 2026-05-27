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

import XCTest
@testable import Waraq

/// Phase 9.8e — procedural thumbnail capture.
final class ProceduralThumbnailTests: XCTestCase {
    @MainActor
    func testProceduralThumbnailGenerationProducesJPG() throws {
        let wallpaper = try XCTUnwrap(
            ProceduralFactory.allBuiltIns.first {
                $0.proceduralKey == "aurora"
            },
            "Aurora built-in should exist"
        )

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let resultURL = try ProceduralThumbnailGenerator.generateThumbnail(
            for: wallpaper, in: tempDir
        )

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: resultURL.path),
            "Generated thumbnail file should exist"
        )
        let attrs = try FileManager.default
            .attributesOfItem(atPath: resultURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        XCTAssertGreaterThan(size, 1000, "JPG should be at least 1KB")
    }

    @MainActor
    func testProceduralThumbnailRejectsNonProcedural() {
        let video = Wallpaper(
            id: "vid-1", name: "Clip", kind: .video,
            addedDate: Date(), relativePath: "vid-1.mp4"
        )
        XCTAssertThrowsError(
            try ProceduralThumbnailGenerator.generateThumbnail(
                for: video, in: FileManager.default.temporaryDirectory
            )
        )
    }
}
