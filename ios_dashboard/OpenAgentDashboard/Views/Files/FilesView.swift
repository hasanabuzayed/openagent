//
//  FilesView.swift
//  OpenAgentDashboard
//
//  Remote file explorer with SFTP-like functionality
//

import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @State private var currentPath = "/root/context"
    @State private var entries: [FileEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedEntry: FileEntry?
    @State private var showingDeleteAlert = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var isImporting = false
    
    private let api = APIService.shared
    
    private var sortedEntries: [FileEntry] {
        let dirs = entries.filter { $0.isDirectory }.sorted { $0.name < $1.name }
        let files = entries.filter { !$0.isDirectory }.sorted { $0.name < $1.name }
        return dirs + files
    }
    
    private var breadcrumbs: [(name: String, path: String)] {
        var crumbs: [(name: String, path: String)] = [("/", "/")]
        var accumulated = ""
        for part in currentPath.split(separator: "/") {
            accumulated += "/" + part
            crumbs.append((String(part), accumulated))
        }
        return crumbs
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Toolbar
                toolbarView
                
                // Breadcrumb navigation
                breadcrumbView
                
                // File list
                if isLoading {
                    LoadingView(message: "Loading files...")
                } else if let error = errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Failed to Load",
                        message: error,
                        action: { Task { await loadDirectory() } },
                        actionLabel: "Retry"
                    )
                } else if sortedEntries.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "Empty Folder",
                        message: "This folder is empty.\nDrag files here or tap Import."
                    )
                } else {
                    fileListView
                }
            }
        }
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingNewFolderAlert = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Files", systemImage: "square.and.arrow.down")
                    }
                    
                    Divider()
                    
                    Button {
                        Task { await loadDirectory() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                Task { await createFolder() }
            }
        }
        .alert("Delete \(selectedEntry?.name ?? "")?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteSelected() }
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task { await handleFileImport(result) }
        }
        .task {
            await loadDirectory()
        }
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                goUp()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.body.weight(.medium))
                    .foregroundStyle(currentPath == "/" ? Theme.textMuted : Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(currentPath == "/")
            
            // Quick nav buttons
            quickNavButton(icon: "📥", label: "context", path: "/root/context")
            quickNavButton(icon: "🔨", label: "work", path: "/root/work")
            quickNavButton(icon: "🛠️", label: "tools", path: "/root/tools")
            
            Spacer()
            
            // Import button
            Button {
                isImporting = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.accent.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private func quickNavButton(icon: String, label: String, path: String) -> some View {
        Button {
            navigateTo(path)
        } label: {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(currentPath.hasPrefix(path) ? Theme.accent : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(currentPath.hasPrefix(path) ? Theme.accent.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(currentPath.hasPrefix(path) ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1)
            )
        }
    }
    
    private var breadcrumbView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(breadcrumbs.enumerated()), id: \.offset) { index, crumb in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.textMuted)
                    }
                    
                    Button {
                        navigateTo(crumb.path)
                    } label: {
                        Text(crumb.name)
                            .font(.caption.weight(index == breadcrumbs.count - 1 ? .semibold : .regular))
                            .foregroundStyle(index == breadcrumbs.count - 1 ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }
    
    private var fileListView: some View {
        List {
            ForEach(sortedEntries) { entry in
                FileRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if entry.isDirectory {
                            navigateTo(entry.path)
                        } else {
                            selectedEntry = entry
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedEntry = entry
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        if entry.isFile {
                            Button {
                                downloadFile(entry)
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle")
                            }
                            .tint(Theme.accent)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Actions
    
    private func loadDirectory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await api.listDirectory(path: currentPath)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func navigateTo(_ path: String) {
        currentPath = path
        Task { await loadDirectory() }
        HapticService.selectionChanged()
    }
    
    private func goUp() {
        guard currentPath != "/" else { return }
        var parts = currentPath.split(separator: "/")
        parts.removeLast()
        currentPath = parts.isEmpty ? "/" : "/" + parts.joined(separator: "/")
        Task { await loadDirectory() }
        HapticService.selectionChanged()
    }
    
    private func createFolder() async {
        guard !newFolderName.isEmpty else { return }
        
        let folderPath = currentPath.hasSuffix("/") 
            ? currentPath + newFolderName 
            : currentPath + "/" + newFolderName
        
        do {
            try await api.createDirectory(path: folderPath)
            newFolderName = ""
            await loadDirectory()
            HapticService.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.error()
        }
    }
    
    private func deleteSelected() async {
        guard let entry = selectedEntry else { return }
        
        do {
            try await api.deleteFile(path: entry.path, recursive: entry.isDirectory)
            selectedEntry = nil
            await loadDirectory()
            HapticService.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.error()
        }
    }
    
    private func downloadFile(_ entry: FileEntry) {
        guard let url = api.downloadURL(path: entry.path) else { return }
        UIApplication.shared.open(url)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let data = try Data(contentsOf: url)
                    let _ = try await api.uploadFile(
                        data: data,
                        fileName: url.lastPathComponent,
                        directory: currentPath
                    )
                } catch {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    HapticService.error()
                    return
                }
            }
            await loadDirectory()
            HapticService.success()
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            HapticService.error()
        }
    }
}

// MARK: - File Row

private struct FileRow: View {
    let entry: FileEntry
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: entry.icon)
                .font(.title3)
                .foregroundStyle(entry.isDirectory ? Theme.accent : Theme.textSecondary)
                .frame(width: 40, height: 40)
                .background(entry.isDirectory ? Theme.accent.opacity(0.15) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(entry.formattedSize)
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                    
                    Text(entry.kind)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            
            Spacer()
            
            // Chevron for directories
            if entry.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationStack {
        FilesView()
    }
}
