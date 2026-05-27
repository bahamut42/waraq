import SwiftUI

@MainActor
final class GalleryViewModel: ObservableObject {
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

    let source: GallerySource = .pixabay

    /// Injected, never `.shared` — mirrors the Phase 9.7
    /// dependency-injection pattern so the view model is testable
    /// and never spins up a parallel library instance.
    private let client = PixabayClient()
    private let downloader: GalleryDownloader

    init(library: WallpaperLibrary) {
        downloader = GalleryDownloader(library: library)
        hasAPIKey = APIKeyStore.hasKey(for: .pixabay)
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else { return }
        APIKeyStore.setKey(trimmed, for: .pixabay)
        hasAPIKey = true
        apiKeyInput = ""
    }

    func clearAPIKey() {
        APIKeyStore.setKey(nil, for: .pixabay)
        hasAPIKey = false
        items = []
        hasSearched = false
    }

    func search() async {
        let query = searchQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else { return }
        guard hasAPIKey else { return }

        isSearching = true
        error = nil
        hasSearched = true
        do {
            let results = try await client.search(query: query)
            items = results
        } catch {
            self.error = error.localizedDescription
            items = []
        }
        isSearching = false
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
