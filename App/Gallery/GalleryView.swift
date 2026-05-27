import AppKit
import SwiftUI

/// Hosts the gallery search experience. A source picker sits at the
/// top; below it, the content adapts to the selected source: a
/// "coming soon" notice for unimplemented sources, an API-key empty
/// state when no key is stored, or the search bar + results grid. The
/// owning pane injects the view model (which holds the injected
/// WallpaperLibrary).
struct GalleryView: View {
    @ObservedObject var viewModel: GalleryViewModel
    @State private var tab: GalleryTab = .online

    private enum GalleryTab: String, CaseIterable, Identifiable {
        case online = "Online Sources"
        case browseWeb = "Browse Web"
        var id: String {
            rawValue
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            tabPicker
            switch tab {
            case .online:
                sourcePicker
                content
            case .browseWeb:
                BrowseWebView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private var tabPicker: some View {
        Picker("View", selection: $tab) {
            ForEach(GalleryTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var sourcePicker: some View {
        Picker(
            "Source",
            selection: Binding(
                get: { viewModel.selectedSource },
                set: { viewModel.setSource($0) }
            )
        ) {
            ForEach(GallerySource.allCases, id: \.self) { source in
                Text(source.displayName).tag(source)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.selectedSource.isImplemented {
            comingSoon
        } else if viewModel.hasAPIKey {
            configuredState
        } else {
            emptyState
        }
    }

    // MARK: Coming soon (unimplemented source)

    private var comingSoon: some View {
        centered {
            messageBlock(
                icon: "clock.badge",
                title: "\(viewModel.selectedSource.displayName) is coming soon",
                subtitle: "This source isn't available yet. Try Pixabay or Pexels in the meantime."
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
                    "Search \(viewModel.selectedSource.displayName) videos…",
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
            errorCard(error)
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

    /// Full error display with the raw API response and a copy button,
    /// so decoding/HTTP failures are diagnosable from the UI alone.
    private func errorCard(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Search failed")
                    .font(.headline)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(error, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy error to clipboard")
            }
            ScrollView {
                Text(error)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
            Text("Connect \(viewModel.selectedSource.displayName) to browse wallpapers")
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("\(viewModel.selectedSource.displayName) offers thousands of free videos. Sign up for a free API key to start browsing.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            if let signup = viewModel.selectedSource.apiKeySignupURL {
                Link(destination: signup) {
                    HStack(spacing: 4) {
                        Text("Get an API key from \(viewModel.selectedSource.displayName)")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .padding(.top, 2)
            }

            VStack(spacing: 8) {
                SecureField(
                    "Paste your \(viewModel.selectedSource.displayName) API key here",
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
