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

import SwiftUI

@MainActor
final class GalleryViewModel: ObservableObject {
    @Published var selectedSource: GallerySource = .pixabay
    @Published var searchQuery: String = ""
    @Published var items: [GalleryItem] = []
    @Published var isSearching: Bool = false
    @Published var error: String?
    @Published var selectedItem: GalleryItem?
    @Published var isDownloading: Bool = false
    @Published var downloadError: String?
    @Published var hasAPIKey: Bool
    @Published var apiKeyInput: String = ""
    @Published var lastAddedTitle: String?
    @Published var hasSearched: Bool = false

    /// Per-source clients. New in 9.8b: search routes to the client
    /// for `selectedSource`. Injected downloader (never `.shared`),
    /// mirroring the Phase 9.7 dependency-injection pattern.
    private let pixabayClient = PixabayClient()
    private let pexelsClient = PexelsClient()
    private let nasaClient = NASAClient()
    private let downloader: GalleryDownloader

    init(library: WallpaperLibrary) {
        downloader = GalleryDownloader(library: library)
        hasAPIKey = Self.keyAvailable(for: .pixabay)
    }

    /// Whether the source is ready to search: sources that don't need
    /// a key (NASA) are always ready; the rest need a stored key.
    private static func keyAvailable(for source: GallerySource) -> Bool {
        !source.requiresAPIKey || APIKeyStore.hasKey(for: source)
    }

    /// Switch the active source. Clears results and re-reads whether
    /// a key is stored for the new source so the UI can show the
    /// right state (grid, empty-key, or coming-soon).
    func setSource(_ source: GallerySource) {
        guard source != selectedSource else { return }
        selectedSource = source
        items = []
        error = nil
        hasSearched = false
        lastAddedTitle = nil
        apiKeyInput = ""
        hasAPIKey = Self.keyAvailable(for: source)
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else { return }
        APIKeyStore.setKey(trimmed, for: selectedSource)
        hasAPIKey = true
        apiKeyInput = ""
    }

    func clearAPIKey() {
        APIKeyStore.setKey(nil, for: selectedSource)
        // NASA needs no key, so it stays ready even after clearing.
        hasAPIKey = Self.keyAvailable(for: selectedSource)
        items = []
        hasSearched = false
    }

    func search() async {
        let query = searchQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else { return }
        guard selectedSource.isImplemented else {
            error = "\(selectedSource.displayName) is coming soon."
            return
        }
        guard hasAPIKey else { return }

        isSearching = true
        error = nil
        hasSearched = true
        do {
            let results = try await search(query: query, on: selectedSource)
            items = results
        } catch {
            self.error = error.localizedDescription
            items = []
        }
        isSearching = false
    }

    private func search(
        query: String, on source: GallerySource
    ) async throws -> [GalleryItem] {
        switch source {
        case .pixabay: try await pixabayClient.search(query: query)
        case .pexels: try await pexelsClient.search(query: query)
        case .nasa: try await nasaClient.search(query: query)
        }
    }

    func select(_ item: GalleryItem) {
        downloadError = nil
        selectedItem = item
    }

    func dismissPreview() {
        selectedItem = nil
        downloadError = nil
    }

    func download(_ item: GalleryItem) async {
        isDownloading = true
        downloadError = nil
        do {
            _ = try await downloader.download(item)
            lastAddedTitle = item.title
            selectedItem = nil
        } catch {
            downloadError = error.localizedDescription
        }
        isDownloading = false
    }
}
