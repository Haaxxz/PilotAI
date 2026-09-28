import SwiftUI
import UniformTypeIdentifiers

public struct BackupView: View {
    @EnvironmentObject private var state: AppState
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportItem: ExportItem? = nil
    @State private var statusMessage: String? = nil
    @State private var isImporting = false
    
    public init() {}
    
    public var body: some View {
        Form {
            Section(header: Text("Export"), footer: Text("Export all conversations, providers, characters, and memory to a JSON file.")) {
                Button(action: exportBackup) {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }
            }
            
            Section(header: Text("Import"), footer: Text("Import a previously exported PilotAI backup. This will merge with existing data.")) {
                Button(action: { showImportPicker = true }) {
                    Label(isImporting ? "Importing..." : "Import Backup", systemImage: "square.and.arrow.down")
                }
                .disabled(isImporting)
            }
            
            if let msg = statusMessage {
                Section {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(msg.lowercased().contains("success") ? .green : .red)
                }
            }
            
            Section(header: Text("Backup Contents")) {
                LabeledContent("Conversations", value: "\(state.conversations.count)")
                LabeledContent("Providers", value: "\(state.providers.count)")
                LabeledContent("Characters", value: "\(state.characters.count)")
                LabeledContent("Memory Size", value: "~\(state.memory.markdown.count / 4) tokens")
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportItem) { item in
            BackupShareSheet(items: [item.url])
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importBackup(result: result)
        }
    }
    
    private func exportBackup() {
        do {
            let backup = BackupData(
                conversations: state.conversations,
                providers: state.providers,
                characters: state.characters,
                memory: state.memory
            )
            let data = try JSONEncoder().encode(backup)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("PilotAI-Backup-\(Date().timeIntervalSince1970).json")
            try data.write(to: url)
            exportItem = ExportItem(url: url)
            statusMessage = "Backup exported successfully."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }
    
    private func importBackup(result: Result<[URL], Error>) {
        isImporting = true
        statusMessage = nil
        do {
            guard let url = try result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                statusMessage = "Cannot access file."
                isImporting = false
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            // Merge
            let existingConvIds = Set(state.conversations.map { $0.id })
            let newConvs = backup.conversations.filter { !existingConvIds.contains($0.id) }
            state.conversations.append(contentsOf: newConvs)
            
            let existingProvIds = Set(state.providers.map { $0.id })
            let newProvs = backup.providers.filter { !existingProvIds.contains($0.id) }
            state.providers.append(contentsOf: newProvs)
            
            let existingCharIds = Set(state.characters.map { $0.id })
            let newChars = backup.characters.filter { !existingCharIds.contains($0.id) }
            state.characters.append(contentsOf: newChars)
            
            if !backup.memory.markdown.isEmpty && state.memory.markdown.isEmpty {
                state.memory = backup.memory
            }
            
            state.saveProviders()
            state.saveCharacters()
            state.saveMemory(state.memory)
            
            statusMessage = "Import successful: +\(newConvs.count) conversations, +\(newProvs.count) providers, +\(newChars.count) characters."
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
        isImporting = false
    }
}

struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct BackupData: Codable {
    var conversations: [Conversation]
    var providers: [ModelProvider]
    var characters: [Character]
    var memory: MemoryDocument
}

struct BackupShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
