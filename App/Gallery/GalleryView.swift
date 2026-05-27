import SwiftUI

/// Hosts the gallery search experience. Shows an API-key empty
/// state when no key is configured, otherwise a search bar plus
/// a 3-column grid of results. The owning pane injects the view
/// model (which holds the injected WallpaperLibrary).
struct GalleryView: View {
    @ObservedObject var viewModel: GalleryViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if viewModel.hasAPIKey {
                configuredState
            } else {
                emptyState
            }
        }
        .sheet(item: $viewModel.selectedItem) { item in
            GalleryItemPreview(
                item: item,
                isDownloading: viewModel.isDownloading,
                downloadError: viewModel.downloadError,
                onAdd: { Task { await viewModel.download(item) } },
                onCancel: { viewModel.dismissPreview() }
            )
        }
    }

    // MARK: Configured (key present)

    private var configuredState: some View {
        VStack(alignment: .leading, spacing: 16) {
            searchBar
            if let added = viewModel.lastAddedTitle {
                addedBanner(added)
            }
            resultsArea
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField(
                    "Search \(viewModel.source.displayName) videos…",
                    text: $viewModel.searchQuery
                )
                .textFieldStyle(.plain)
                .onSubmit { Task { await viewModel.search() } }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Button("Search") { Task { await viewModel.search() } }
                .buttonStyle(.borderedProminent)
                .disabled(
                    viewModel.searchQuery.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || viewModel.isSearching
                )
        }
    }

    private func addedBanner(_ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Added “\(title)” to your Library.")
                .font(.system(size: 12))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var resultsArea: some View {
        if viewModel.isSearching {
            centered { ProgressView("Searching…") }
        } else if let error = viewModel.error {
            centered {
                messageBlock(
                    icon: "exclamationmark.triangle",
                    title: "Search failed",
                    subtitle: error
                )
            }
        } else if viewModel.items.isEmpty, viewModel.hasSearched {
            centered {
                messageBlock(
                    icon: "magnifyingglass",
                    title: "No results",
                    subtitle: "Try a different search term."
                )
            }
        } else if viewModel.items.isEmpty {
            centered {
                messageBlock(
                    icon: "photo.stack",
                    title: "Search to browse",
                    subtitle: "Type a term like “aurora”, “ocean”, or “space”."
                )
            }
        } else {
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.items) { item in
                    GalleryItemTile(item: item)
                        .onTapGesture { viewModel.select(item) }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: Empty (no key)

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 8)
            Image(systemName: "photo.stack")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Connect \(viewModel.source.displayName) to browse wallpapers")
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("\(viewModel.source.displayName) offers thousands of free videos. Sign up for a free API key to start browsing.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if let signup = viewModel.source.apiKeySignupURL {
                Link(destination: signup) {
                    HStack(spacing: 4) {
                        Text("Get an API key from \(viewModel.source.displayName)")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .padding(.top, 2)
            }

            VStack(spacing: 8) {
                SecureField(
                    "Paste your \(viewModel.source.displayName) API key here",
                    text: $viewModel.apiKeyInput
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 360)
                .onSubmit { viewModel.saveAPIKey() }

                Button("Save Key") { viewModel.saveAPIKey() }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.apiKeyInput.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: Helpers

    private func centered(
        @ViewBuilder _ content: () -> some View
    ) -> some View {
        VStack {
            Spacer(minLength: 40)
            content()
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func messageBlock(
        icon: String, title: String, subtitle: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
