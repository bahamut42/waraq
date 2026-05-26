import AppKit
import SwiftUI

/// Modal sheet for choosing apps exempt from fullscreen pause.
struct ExemptionListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fullscreenExemptions")
    private var exemptionsData: Data = .init()

    @State private var selected: Set<String> = []
    @State private var apps: [AppEntry] = []
    @State private var searchQuery: String = ""

    struct AppEntry: Identifiable, Hashable {
        let id: String // bundle identifier or display name
        let displayName: String
        let icon: NSImage?
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            appList
            footer
        }
        .frame(width: 460, height: 540)
        .onAppear {
            loadApps()
            loadSelections()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Exempt apps")
                .font(.system(size: 15, weight: .medium))
            Text("These apps will not trigger pause when fullscreen.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            TextField("Search apps", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var appList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredApps) { app in
                    appRow(app)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func appRow(_ app: AppEntry) -> some View {
        let isOn = Binding(
            get: { selected.contains(app.id) },
            set: { on in
                if on { selected.insert(app.id) }
                else { selected.remove(app.id) }
            }
        )
        return HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 22, height: 22)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 22, height: 22)
            }
            Text(app.displayName)
                .font(.system(size: 12))
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.checkbox).labelsHidden()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var footer: some View {
        HStack {
            Text("\(selected.count) selected")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancel") { dismiss() }
                .controlSize(.large)
            Button("Done") {
                saveSelections()
                dismiss()
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.03))
    }

    private var filteredApps: [AppEntry] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return apps }
        return apps.filter {
            $0.displayName.localizedCaseInsensitiveContains(q)
        }
    }

    private func loadApps() {
        let fm = FileManager.default
        var entries: [AppEntry] = []
        let dirs = [
            "/Applications",
            "\(NSHomeDirectory())/Applications",
            "/System/Applications",
        ]
        for dir in dirs {
            guard let contents = try? fm.contentsOfDirectory(
                atPath: dir
            ) else { continue }
            for name in contents where name.hasSuffix(".app") {
                let path = "\(dir)/\(name)"
                let displayName = (name as NSString).deletingPathExtension
                let bundle = Bundle(path: path)
                let id = bundle?.bundleIdentifier ?? displayName
                let icon = NSWorkspace.shared.icon(forFile: path)
                icon.size = NSSize(width: 22, height: 22)
                entries.append(AppEntry(
                    id: id, displayName: displayName, icon: icon
                ))
            }
        }
        entries.sort {
            $0.displayName.localizedCaseInsensitiveCompare(
                $1.displayName
            ) == .orderedAscending
        }
        apps = entries
    }

    private func loadSelections() {
        guard let arr = try? JSONDecoder().decode(
            [String].self, from: exemptionsData
        ) else { return }
        selected = Set(arr)
    }

    private func saveSelections() {
        let arr = Array(selected)
        if let data = try? JSONEncoder().encode(arr) {
            exemptionsData = data
            UserDefaults.standard.set(arr, forKey: "fullscreenExemptions")
        }
    }
}
